//
//  MovementLedgerTests.swift
//  BudgetSpyTests
//

import CoreData
import Testing
@testable import BudgetSpy

@MainActor
struct MovementLedgerTests {
    private let context = makeInMemoryContext()
    private var ledger: MovementLedger { MovementLedger(context: context) }

    private func draft(
        _ kind: MovementKind,
        _ amount: Decimal,
        from origin: Account,
        to destination: Account? = nil,
        description: String = "Compra de café"
    ) -> MovementDraft {
        MovementDraft(kind: kind, amount: amount, description: description, originAccountID: origin.id, destinationAccountID: destination?.id)
    }

    private func expectBalancesMatchMovements(_ accounts: Account...) {
        for account in accounts {
            #expect(account.balanceValue == movementTotal(of: account), "\(account.name ?? "")")
        }
    }

    // MARK: - Create, update, delete

    @Test func creatingAnExpenseUpdatesTheBalance() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)

        let movement = try ledger.create(draft(.expense, 10_000, from: payroll))
        try context.save()

        #expect(movement.amountValue == -10_000)
        #expect(movement.kind == .expense)
        #expect(movement.destinationAccount == nil)
        #expect(movement.movementDescription == "Compra de café")
        #expect(movement.date == Calendar.current.startOfDay(for: .now))
        #expect(payroll.balanceValue == 90_000)
        expectBalancesMatchMovements(payroll)
    }

    @Test func creatingATransferUpdatesBothAccounts() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", in: context)
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 50_000, in: context)

        try ledger.create(draft(.transfer, 20_000, from: payroll, to: house))
        try ledger.create(draft(.transfer, 30_000, from: payroll, to: visa))
        try context.save()

        #expect(payroll.balanceValue == 50_000)
        #expect(house.balanceValue == 20_000)
        #expect(visa.balanceValue == 20_000)
        expectBalancesMatchMovements(payroll, house, visa)
    }

    @Test func invalidMovementThrowsWithoutChangingAnything() throws {
        let payroll = try insertAccount("Nómina", balance: 50_000, in: context)
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 100_000, in: context)

        #expect(throws: MovementLedgerError.balanceRuleViolated(.insufficientFunds(accountName: "Nómina", available: 50_000))) {
            try ledger.create(draft(.expense, 60_000, from: payroll))
        }
        #expect(throws: MovementLedgerError.invalidMovement) {
            try ledger.create(draft(.transfer, 10_000, from: visa, to: payroll))
        }
        #expect(payroll.balanceValue == 50_000)
        #expect(context.insertedObjects.isEmpty)
    }

    @Test func changingExpenseToIncomeAddsTwiceTheAmount() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let movement = try ledger.create(draft(.expense, 10_000, from: payroll))

        try ledger.update(movement, with: draft(.income, 10_000, from: payroll))
        try context.save()

        #expect(payroll.balanceValue == 110_000)
        #expect(movement.amountValue == 10_000)
        #expect(movement.kind == .income)
        expectBalancesMatchMovements(payroll)
    }

    @Test func changingTheAccountMovesTheEffect() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", balance: 50_000, in: context)
        let movement = try ledger.create(draft(.expense, 10_000, from: payroll))

        try ledger.update(movement, with: draft(.expense, 10_000, from: house))
        try context.save()

        #expect(payroll.balanceValue == 100_000)
        #expect(house.balanceValue == 40_000)
        expectBalancesMatchMovements(payroll, house)
    }

    @Test func changingTransferToExpenseDropsTheDestination() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", in: context)
        let movement = try ledger.create(draft(.transfer, 20_000, from: payroll, to: house))

        try ledger.update(movement, with: draft(.expense, 20_000, from: payroll, to: house))
        try context.save()

        #expect(movement.destinationAccount == nil)
        #expect(payroll.balanceValue == 80_000)
        #expect(house.balanceValue == 0)
        expectBalancesMatchMovements(payroll, house)
    }

    @Test func invalidUpdateThrowsWithoutChangingAnything() throws {
        let payroll = try insertAccount("Nómina", in: context)
        let movement = try ledger.create(draft(.income, 50_000, from: payroll))
        try ledger.create(draft(.expense, 40_000, from: payroll))
        try context.save()

        #expect(throws: MovementLedgerError.self) {
            try ledger.update(movement, with: draft(.expense, 50_000, from: payroll))
        }
        #expect(payroll.balanceValue == 10_000)
        #expect(movement.kind == .income)
    }

    @Test func deletingAnExpenseGivesTheMoneyBack() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let movement = try ledger.create(draft(.expense, 10_000, from: payroll))
        try context.save()

        try ledger.delete(movement)
        try context.save()

        #expect(payroll.balanceValue == 100_000)
        #expect(try fetchAll(Movement.self, in: context).count == 1)
        expectBalancesMatchMovements(payroll)
    }

    @Test func deletionIsBlockedWhenTheBalanceWouldBeNegative() throws {
        let payroll = try insertAccount("Nómina", in: context)
        let income = try ledger.create(draft(.income, 50_000, from: payroll))
        try ledger.create(draft(.expense, 20_000, from: payroll))
        try context.save()

        #expect(throws: MovementLedgerError.deletionBlocked(.savingsBelowZero(accountName: "Nómina", resultingBalance: -20_000))) {
            try ledger.delete(income)
        }
        #expect(payroll.balanceValue == 30_000)
        #expect(income.isDeleted == false)
    }

    // MARK: - Initial balance and adjustments (RF15, RF16)

    @Test func savingsAccountGetsAnInitialIncome() throws {
        let createdAt = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let payroll = try insertAccount("Nómina", balance: 500_000, createdAt: createdAt, in: context)

        let movement = try #require(payroll.originMovementList.first)
        #expect(payroll.originMovementList.count == 1)
        #expect(movement.kind == .income)
        #expect(movement.amountValue == 500_000)
        #expect(movement.movementDescription == "Saldo inicial")
        #expect(movement.date == Calendar.current.startOfDay(for: createdAt))
        #expect(payroll.balanceValue == 500_000)
    }

    @Test func creditCardGetsAnInitialExpense() throws {
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 1_200_000, in: context)

        let movement = try #require(visa.originMovementList.first)
        #expect(movement.kind == .expense)
        #expect(movement.amountValue == 1_200_000)
        #expect(visa.balanceValue == 1_200_000)
    }

    @Test(arguments: [AccountKind.savings, AccountKind.creditCard])
    func zeroBalanceCreatesNoMovement(kind: AccountKind) throws {
        let account = try insertAccount("Cuenta", kind: kind, in: context)
        #expect(account.originMovementList.isEmpty)
    }

    @Test func loweringSavingsRecordsAnExpenseAdjustment() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)

        try ledger.recordAdjustment(for: payroll, to: 80_000)
        try context.save()

        let adjustment = try #require(payroll.originMovementList.first { $0.movementDescription == "Ajuste de saldo" })
        #expect(adjustment.kind == .expense)
        #expect(adjustment.amountValue == -20_000)
        #expect(adjustment.date == Calendar.current.startOfDay(for: .now))
        #expect(payroll.balanceValue == 80_000)
        expectBalancesMatchMovements(payroll)
    }

    @Test func unchangedBalanceRecordsNoAdjustment() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)

        try ledger.recordAdjustment(for: payroll, to: 100_000)

        #expect(payroll.originMovementList.count == 1)
    }

    // MARK: - Account deletion (RF17)

    @Test func deletingTheDestinationTurnsTheTransferIntoAnExpense() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", in: context)
        let transfer = try ledger.create(draft(.transfer, 20_000, from: payroll, to: house))
        try context.save()

        try ledger.prepareDeletion(of: house)
        context.delete(house)
        try context.save()

        #expect(transfer.kind == .expense)
        #expect(transfer.destinationAccount == nil)
        #expect(transfer.originAccount == payroll)
        #expect(transfer.amountValue == -20_000)
        #expect(payroll.balanceValue == 80_000)
        expectBalancesMatchMovements(payroll)
    }

    @Test func deletingTheOriginTurnsTheTransferIntoAnIncome() throws {
        let payroll = try insertAccount("Nómina", balance: 100_000, in: context)
        let house = try insertAccount("Ahorros casa", in: context)
        let visa = try insertAccount("Visa", kind: .creditCard, balance: 50_000, in: context)
        let toHouse = try ledger.create(draft(.transfer, 20_000, from: payroll, to: house))
        let toVisa = try ledger.create(draft(.transfer, 30_000, from: payroll, to: visa))
        try ledger.create(draft(.expense, 5_000, from: payroll))
        try context.save()

        try ledger.prepareDeletion(of: payroll)
        context.delete(payroll)
        try context.save()

        #expect(toHouse.kind == .income)
        #expect(toHouse.originAccount == house)
        #expect(toHouse.destinationAccount == nil)
        #expect(toHouse.amountValue == 20_000)
        #expect(toVisa.kind == .income)
        #expect(toVisa.originAccount == visa)
        #expect(toVisa.amountValue == -30_000)
        #expect(house.balanceValue == 20_000)
        #expect(visa.balanceValue == 20_000)
        // Saldo inicial and the expense of the deleted account are gone; its transfers survive.
        #expect(try fetchAll(Movement.self, in: context).count == 3)
        expectBalancesMatchMovements(house, visa)
    }
}
