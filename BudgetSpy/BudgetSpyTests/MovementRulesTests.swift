//
//  MovementRulesTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementRulesTests {
    private let rules = MovementRules()

    private static let payroll = AccountSnapshot(id: UUID(), kind: .savings, name: "Nómina", balance: 50_000, creditLimit: nil)
    private static let house = AccountSnapshot(id: UUID(), kind: .savings, name: "Ahorros casa", balance: 0, creditLimit: nil)
    private static let visa = AccountSnapshot(id: UUID(), kind: .creditCard, name: "Visa", balance: 100_000, creditLimit: 5_000_000)

    private func accounts(_ snapshots: AccountSnapshot...) -> MovementRules.Accounts {
        Dictionary(uniqueKeysWithValues: snapshots.map { ($0.id, $0) })
    }

    private func snapshot(_ base: AccountSnapshot, balance: Decimal) -> AccountSnapshot {
        AccountSnapshot(id: base.id, kind: base.kind, name: base.name, balance: balance, creditLimit: base.creditLimit)
    }

    private func effect(_ kind: MovementKind, _ amount: Decimal, from origin: AccountSnapshot, to destination: AccountSnapshot? = nil) -> MovementEffect {
        MovementEffect(kind: kind, amount: amount, originID: origin.id, destinationID: destination?.id)
    }

    // MARK: - Sign and delta, every cell of the table

    @Test(arguments: [
        (MovementKind.expense, AccountKind.savings, Decimal(-10_000)),
        (MovementKind.expense, AccountKind.creditCard, Decimal(10_000)),
        (MovementKind.income, AccountKind.savings, Decimal(10_000)),
        (MovementKind.income, AccountKind.creditCard, Decimal(-10_000)),
        (MovementKind.transfer, AccountKind.savings, Decimal(-10_000)),
    ])
    func originSign(kind: MovementKind, originKind: AccountKind, expected: Decimal) {
        #expect(rules.signedAmount(of: kind, amount: 10_000, originKind: originKind) == expected)
    }

    @Test(arguments: [
        (AccountKind.savings, Decimal(10_000)),
        (AccountKind.creditCard, Decimal(-10_000)),
    ])
    func destinationSign(destinationKind: AccountKind, expected: Decimal) {
        #expect(rules.destinationSignedAmount(amount: 10_000, destinationKind: destinationKind) == expected)
    }

    @Test func transferDeltasTouchBothAccounts() {
        let all = accounts(Self.payroll, Self.house, Self.visa)

        #expect(rules.deltas(of: effect(.transfer, 20_000, from: Self.payroll, to: Self.house), accounts: all)
            == [Self.payroll.id: -20_000, Self.house.id: 20_000])
        #expect(rules.deltas(of: effect(.transfer, 30_000, from: Self.payroll, to: Self.visa), accounts: all)
            == [Self.payroll.id: -30_000, Self.visa.id: -30_000])
    }

    @Test func transferFromCreditCardIsNotAllowed() {
        let all = accounts(Self.payroll, Self.visa)
        #expect(rules.isAllowed(effect(.transfer, 10_000, from: Self.visa, to: Self.payroll), accounts: all) == false)
        #expect(rules.isAllowed(effect(.transfer, 10_000, from: Self.payroll, to: Self.payroll), accounts: all) == false)
        #expect(rules.isAllowed(effect(.transfer, 10_000, from: Self.payroll), accounts: all) == false)
        #expect(rules.isAllowed(effect(.expense, 0, from: Self.payroll), accounts: all) == false)
        #expect(rules.isAllowed(effect(.transfer, 10_000, from: Self.payroll, to: Self.visa), accounts: all))
    }

    // MARK: - Balance rules (CA7, CA8, CA9)

    @Test func savingsExpenseCannotLeaveBalanceBelowZero() {
        let all = accounts(Self.payroll)

        let error = rules.balanceError(applying: effect(.expense, 60_000, from: Self.payroll), accounts: all)
        #expect(error == .insufficientFunds(accountName: "Nómina", available: 50_000))
        #expect(error?.message == "Saldo insuficiente en Nómina. Disponible: $ 50.000,00")

        #expect(rules.balanceError(applying: effect(.expense, 50_000, from: Self.payroll), accounts: all) == nil)
        #expect(rules.balanceError(applying: effect(.transfer, 60_000, from: Self.payroll, to: Self.house),
                                   accounts: accounts(Self.payroll, Self.house)) != nil)
    }

    @Test func savingsIncomeAndTransferInAreAlwaysValid() {
        let all = accounts(Self.payroll, Self.house)
        #expect(rules.balanceError(applying: effect(.income, 9_000_000, from: Self.house), accounts: all) == nil)
        #expect(rules.balanceError(applying: effect(.transfer, 50_000, from: Self.payroll, to: Self.house), accounts: all) == nil)
    }

    @Test func creditCardExpenseCannotExceedLimit() {
        let visa = snapshot(Self.visa, balance: 4_800_000)
        let all = accounts(visa)

        let error = rules.balanceError(applying: effect(.expense, 300_000, from: visa), accounts: all)
        #expect(error == .exceedsCreditLimit(accountName: "Visa", availableCredit: 200_000))
        #expect(error?.message == "Supera el límite de Visa. Cupo disponible: $ 200.000,00")

        #expect(rules.balanceError(applying: effect(.expense, 200_000, from: visa), accounts: all) == nil)
    }

    @Test func creditCardIncomeCannotExceedDebt() {
        let all = accounts(Self.visa)

        let error = rules.balanceError(applying: effect(.income, 150_000, from: Self.visa), accounts: all)
        #expect(error == .exceedsDebt(accountName: "Visa", debt: 100_000))
        #expect(error?.message == "El valor supera la deuda de Visa: $ 100.000,00")

        #expect(rules.balanceError(applying: effect(.income, 100_000, from: Self.visa), accounts: all) == nil)
    }

    @Test func transferToCreditCardCannotExceedDebt() {
        let payroll = snapshot(Self.payroll, balance: 500_000)
        let all = accounts(payroll, Self.visa)

        let error = rules.balanceError(applying: effect(.transfer, 150_000, from: payroll, to: Self.visa), accounts: all)
        #expect(error == .exceedsDebt(accountName: "Visa", debt: 100_000))

        #expect(rules.balanceError(applying: effect(.transfer, 100_000, from: payroll, to: Self.visa), accounts: all) == nil)
    }

    // MARK: - Editing

    @Test func editingRevertsTheOriginalEffectFirst() {
        let payroll = snapshot(Self.payroll, balance: 20_000)
        let all = accounts(payroll)
        let original = effect(.expense, 30_000, from: payroll)

        #expect(rules.balanceError(applying: effect(.expense, 50_000, from: payroll), replacing: original, accounts: all) == nil)
        #expect(rules.balanceError(applying: effect(.expense, 50_001, from: payroll), replacing: original, accounts: all)
            == .insufficientFunds(accountName: "Nómina", available: 50_000))
    }

    @Test func changingIncomeToExpenseCanLeaveBalanceNegative() {
        let payroll = snapshot(Self.payroll, balance: 10_000)
        let all = accounts(payroll)

        let error = rules.balanceError(
            applying: effect(.expense, 50_000, from: payroll),
            replacing: effect(.income, 50_000, from: payroll),
            accounts: all
        )
        #expect(error == .insufficientFunds(accountName: "Nómina", available: -40_000))
    }

    @Test func changingAccountChecksTheAccountLeftBehind() {
        let payroll = snapshot(Self.payroll, balance: 30_000)
        let all = accounts(payroll, Self.house)

        let error = rules.balanceError(
            applying: effect(.income, 50_000, from: Self.house),
            replacing: effect(.income, 50_000, from: payroll),
            accounts: all
        )
        #expect(error == .insufficientFunds(accountName: "Nómina", available: -20_000))
    }

    // MARK: - Deletion

    @Test func deletingIncomeCannotLeaveSavingsNegative() {
        let payroll = snapshot(Self.payroll, balance: 30_000)

        let error = rules.deletionError(of: effect(.income, 50_000, from: payroll), accounts: accounts(payroll))
        #expect(error == .savingsBelowZero(accountName: "Nómina", resultingBalance: -20_000))
        #expect(error?.message == "No se puede eliminar el movimiento: el saldo de Nómina quedaría en -$ 20.000,00")

        #expect(rules.deletionError(of: effect(.expense, 10_000, from: payroll), accounts: accounts(payroll)) == nil)
    }

    @Test func deletingCreditCardMovementsKeepsDebtWithinBounds() {
        let visa = snapshot(Self.visa, balance: 4_950_000)
        let all = accounts(visa)

        let aboveLimit = rules.deletionError(of: effect(.income, 100_000, from: visa), accounts: all)
        #expect(aboveLimit?.justification == "la deuda de Visa quedaría en $ 5.050.000,00 y supera el límite de $ 5.000.000,00")

        let belowZero = rules.deletionError(of: effect(.expense, 100_000, from: Self.visa), accounts: accounts(Self.visa))
        #expect(belowZero == nil)
        let tooLarge = rules.deletionError(of: effect(.expense, 150_000, from: Self.visa), accounts: accounts(Self.visa))
        #expect(tooLarge?.justification == "la deuda de Visa quedaría en -$ 50.000,00")
    }

    // MARK: - Adjustments (RF15, RF16)

    @Test(arguments: [
        (AccountKind.savings, Decimal(100_000), Decimal(130_000), MovementKind.income, Decimal(30_000)),
        (AccountKind.savings, Decimal(100_000), Decimal(80_000), MovementKind.expense, Decimal(-20_000)),
        (AccountKind.creditCard, Decimal(100_000), Decimal(150_000), MovementKind.expense, Decimal(50_000)),
        (AccountKind.creditCard, Decimal(100_000), Decimal(40_000), MovementKind.income, Decimal(-60_000)),
    ])
    func adjustmentKindFollowsTheMoney(accountKind: AccountKind, old: Decimal, new: Decimal, kind: MovementKind, signedAmount: Decimal) {
        let adjustment = rules.adjustment(for: accountKind, from: old, to: new)
        #expect(adjustment?.kind == kind)
        #expect(adjustment?.signedAmount == signedAmount)
    }

    @Test func unchangedBalanceNeedsNoAdjustment() {
        #expect(rules.adjustment(for: .savings, from: 100_000, to: 100_000) == nil)
    }
}
