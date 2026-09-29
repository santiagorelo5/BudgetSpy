//
//  AccountKindTests.swift
//  BudgetSpyTests
//

import Testing
@testable import BudgetSpy

@MainActor
struct AccountKindTests {
    @Test func savingsTexts() {
        #expect(AccountKind.savings.displayName == "Cuenta de Ahorros")
        #expect(AccountKind.savings.balanceTitle == "Saldo en la cuenta")
        #expect(AccountKind.savings.requiresCreditLimit == false)
    }

    @Test func creditCardTexts() {
        #expect(AccountKind.creditCard.displayName == "Tarjeta de Crédito")
        #expect(AccountKind.creditCard.balanceTitle == "Deuda a la fecha")
        #expect(AccountKind.creditCard.requiresCreditLimit == true)
    }

    @Test func abbreviations() {
        #expect(AccountKind(rawValue: "CA") == .savings)
        #expect(AccountKind(rawValue: "TC") == .creditCard)
    }
}
