//
//  AccountCardContentTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct AccountCardContentTests {
    @Test func emptyDraftShowsPlaceholders() {
        let content = AccountCardContent(draft: AccountDraft())

        #expect(content.kind == .savings)
        #expect(content.isNamePlaceholder)
        #expect(content.displayedName == "Nombre de la cuenta")
        #expect(content.maskedLastFourDigits == "**** ----")
        #expect(content.formattedBalance == "$ 0,00")
    }

    @Test func incompleteDigitsArePadded() {
        let content = AccountCardContent(kind: .savings, name: "Nómina", lastFourDigits: "48", balance: 0)
        #expect(content.maskedLastFourDigits == "**** 48--")
    }

    @Test func savingsAccessibilityLabel() {
        let content = AccountCardContent(kind: .savings, name: "Nómina", lastFourDigits: "4821", balance: 1_250_000)
        #expect(content.accessibilityLabel == "Cuenta de Ahorros, Nómina, terminada en 4821, saldo $ 1.250.000,00")
    }

    @Test func creditCardAccessibilityLabel() {
        let content = AccountCardContent(kind: .creditCard, name: "Visa", lastFourDigits: "1234", balance: 1_200_000)
        #expect(content.accessibilityLabel == "Tarjeta de Crédito, Visa, terminada en 1234, deuda $ 1.200.000,00")
    }
}
