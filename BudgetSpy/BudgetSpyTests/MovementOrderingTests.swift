//
//  MovementOrderingTests.swift
//  BudgetSpyTests
//

import CoreData
import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementOrderingTests {
    private let context = makeInMemoryContext()
    private let today = Calendar.current.startOfDay(for: .now)
    private var yesterday: Date { Calendar.current.date(byAdding: .day, value: -1, to: today)! }

    private func create(_ kind: MovementKind, _ amount: Decimal, _ description: String, date: Date, from origin: Account, to destination: Account? = nil) throws {
        try MovementLedger(context: context).create(MovementDraft(
            kind: kind, amount: amount, description: description, date: date,
            originAccountID: origin.id, destinationAccountID: destination?.id
        ))
    }

    private func descriptions(for account: Account) -> [String] {
        MovementOrdering.sorted(account.originMovementList + account.destinationMovementList, for: account)
            .compactMap(\.movementDescription)
    }

    @Test func keyOrderingRules() {
        let base = MovementOrdering.Key(date: today, signedAmount: 0, createdAt: today)
        let newerDate = MovementOrdering.Key(date: today.addingTimeInterval(86_400), signedAmount: -1, createdAt: today)
        let larger = MovementOrdering.Key(date: today, signedAmount: 50_000, createdAt: today)
        let newerCreation = MovementOrdering.Key(date: today, signedAmount: 0, createdAt: today.addingTimeInterval(1))

        #expect(MovementOrdering.areInIncreasingOrder(newerDate, base))
        #expect(MovementOrdering.areInIncreasingOrder(larger, base))
        #expect(MovementOrdering.areInIncreasingOrder(newerCreation, base))
        #expect(MovementOrdering.areInIncreasingOrder(base, base) == false)
    }

    @Test func sortsByDateThenSignedAmountThenCreation() throws {
        let payroll = try insertAccount("Nómina", balance: 1_000_000, createdAt: Calendar.current.date(byAdding: .day, value: -5, to: today)!, in: context)
        try create(.expense, 10_000, "Ayer", date: yesterday, from: payroll)
        try create(.expense, 10_000, "Gasto viejo", date: today, from: payroll)
        try create(.income, 50_000, "Ingreso", date: today, from: payroll)
        try create(.expense, 10_000, "Gasto nuevo", date: today, from: payroll)

        #expect(descriptions(for: payroll) == ["Ingreso", "Gasto nuevo", "Gasto viejo", "Ayer", "Saldo inicial"])
    }

    @Test func transferIsOrderedWithTheSignOfTheFocusedAccount() throws {
        let creation = Calendar.current.date(byAdding: .day, value: -5, to: today)!
        let payroll = try insertAccount("Nómina", balance: 1_000_000, createdAt: creation, in: context)
        let house = try insertAccount("Ahorros casa", balance: 100_000, createdAt: creation, in: context)
        try create(.transfer, 20_000, "Transferencia", date: today, from: payroll, to: house)
        try create(.expense, 5_000, "Gasto casa", date: today, from: house)
        try create(.expense, 30_000, "Gasto nómina", date: today, from: payroll)

        // In Nómina the transfer is -20.000, above -30.000; in Ahorros casa it is +20.000, above -5.000.
        #expect(descriptions(for: payroll).prefix(2) == ["Transferencia", "Gasto nómina"])
        #expect(descriptions(for: house).prefix(2) == ["Transferencia", "Gasto casa"])
    }
}
