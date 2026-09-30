//
//  MovementRowContentTests.swift
//  BudgetSpyTests
//

import CoreData
import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementRowContentTests {
    private let context = makeInMemoryContext()

    private func create(_ kind: MovementKind, _ amount: Decimal, from origin: Account, to destination: Account? = nil) throws -> Movement {
        try MovementLedger(context: context).create(MovementDraft(
            kind: kind, amount: amount, description: "Compra de café",
            originAccountID: origin.id, destinationAccountID: destination?.id
        ))
    }

    @Test func expenseOnSavingsIsRedAndNegative() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let content = MovementRowContent(movement: try create(.expense, 10_000, from: payroll), perspective: payroll)

        #expect(content.role == .outgoing)
        #expect(content.formattedAmount == "-$ 10.000,00")
        #expect(content.systemImage == "arrow.up.right.circle.fill")
    }

    @Test func expenseOnCreditCardIsRedAndPositive() throws {
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 100_000, in: context)
        let content = MovementRowContent(movement: try create(.expense, 10_000, from: visa), perspective: visa)

        #expect(content.role == .outgoing)
        #expect(content.formattedAmount == "$ 10.000,00")
    }

    @Test func incomeOnSavingsIsGreenAndPositive() throws {
        let payroll = try insertAccount("Nómina", in: context)
        let content = MovementRowContent(movement: try create(.income, 10_000, from: payroll), perspective: payroll)

        #expect(content.role == .incoming)
        #expect(content.formattedAmount == "$ 10.000,00")
    }

    @Test func transferIsRedInOriginAndGreenInDestination() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", in: context)
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 50_000, in: context)
        let toHouse = try create(.transfer, 20_000, from: payroll, to: house)
        let toVisa = try create(.transfer, 30_000, from: payroll, to: visa)

        let inOrigin = MovementRowContent(movement: toHouse, perspective: payroll)
        #expect(inOrigin.role == .outgoing)
        #expect(inOrigin.formattedAmount == "-$ 20.000,00")

        let inDestination = MovementRowContent(movement: toHouse, perspective: house)
        #expect(inDestination.role == .incoming)
        #expect(inDestination.formattedAmount == "$ 20.000,00")

        let inCreditCard = MovementRowContent(movement: toVisa, perspective: visa)
        #expect(inCreditCard.role == .incoming)
        #expect(inCreditCard.formattedAmount == "-$ 30.000,00")
    }

    @Test func formatsDateAndReadsAsOneSentence() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30))!
        let content = MovementRowContent(kind: .expense, description: "Compra de café", date: date, signedAmount: -10_000, role: .outgoing)

        #expect(content.formattedDate == "30 sep 2026")
        #expect(content.accessibilityLabel == "Gasto, Compra de café, 30 de septiembre de 2026, menos 10.000 pesos")
    }
}
