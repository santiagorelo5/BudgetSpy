//
//  AccountValidatorTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct AccountValidatorTests {
    private let validator = AccountValidator()
    private let validSavings = AccountDraft(
        kind: .savings, name: "Nómina Bancolombia", lastFourDigits: "4821", balance: 1_250_000
    )

    @Test func validSavingsHasNoErrors() {
        #expect(validator.errors(for: validSavings).isEmpty)
    }

    @Test(arguments: ["", "   "])
    func emptyNameIsInvalid(name: String) {
        var draft = validSavings
        draft.name = name
        #expect(validator.errors(for: draft)[.name] == .emptyName)
    }

    @Test func nameLongerThanTwentyIsInvalid() {
        var draft = validSavings
        draft.name = String(repeating: "a", count: 21)
        #expect(validator.errors(for: draft)[.name] == .nameTooLong)
    }

    @Test(arguments: ["482", "48A1", "", "48211"])
    func invalidLastFourDigits(digits: String) {
        var draft = validSavings
        draft.lastFourDigits = digits
        #expect(validator.errors(for: draft)[.lastFourDigits] == .incompleteLastFourDigits)
    }

    @Test(arguments: [Decimal(0), Decimal(1_250_000)])
    func nonNegativeBalanceIsValid(balance: Decimal) {
        var draft = validSavings
        draft.balance = balance
        #expect(validator.errors(for: draft)[.balance] == nil)
    }

    @Test func negativeBalanceIsInvalid() {
        var draft = validSavings
        draft.balance = -1
        #expect(validator.errors(for: draft)[.balance] == .negativeBalance)
    }

    @Test func creditCardWithLimitAboveDebtIsValid() {
        let draft = AccountDraft(
            kind: .creditCard, name: "Visa", lastFourDigits: "1234", balance: 1_200_000, creditLimit: 5_000_000
        )
        #expect(validator.errors(for: draft).isEmpty)
    }

    @Test func creditCardWithLimitBelowDebtIsInvalid() {
        let draft = AccountDraft(
            kind: .creditCard, name: "Visa", lastFourDigits: "1234", balance: 1_200_000, creditLimit: 1_000_000
        )
        #expect(validator.errors(for: draft)[.creditLimit] == .creditLimitBelowDebt)
    }

    @Test func creditCardWithZeroLimitIsInvalid() {
        let draft = AccountDraft(kind: .creditCard, name: "Visa", lastFourDigits: "1234", balance: 0, creditLimit: 0)
        #expect(validator.errors(for: draft)[.creditLimit] == .missingCreditLimit)
    }

    @Test func savingsIgnoresCreditLimit() {
        var draft = validSavings
        draft.creditLimit = 0
        #expect(validator.errors(for: draft)[.creditLimit] == nil)
    }

    @Test func messagesMatchSpec() {
        #expect(AccountValidationError.emptyName.message == "Ingresa un nombre")
        #expect(AccountValidationError.incompleteLastFourDigits.message == "Ingresa los últimos 4 dígitos")
        #expect(AccountValidationError.missingCreditLimit.message == "Ingresa un límite mayor a 0")
        #expect(AccountValidationError.creditLimitBelowDebt.message == "El límite debe ser mayor o igual a la deuda")
    }
}
