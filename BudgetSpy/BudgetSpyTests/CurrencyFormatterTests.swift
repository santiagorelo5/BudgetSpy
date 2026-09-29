//
//  CurrencyFormatterTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct CurrencyFormatterTests {
    @Test(arguments: [
        (Decimal(0), "$ 0,00"),
        (Decimal(1000), "$ 1.000,00"),
        (Decimal(1_250_000), "$ 1.250.000,00"),
        (Decimal(-1000), "$ -1.000,00"),
        (Decimal(string: "1250.5")!, "$ 1.250,50"),
    ])
    func formatsCOP(amount: Decimal, expected: String) {
        #expect(CurrencyFormatter.string(from: amount) == expected)
    }
}
