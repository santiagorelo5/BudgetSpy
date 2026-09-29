//
//  CurrencyParserTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct CurrencyParserTests {
    @Test(arguments: [
        ("", Decimal(0)),
        ("125000", Decimal(1250)),
        ("$ 1.250,0", Decimal(125)),
        ("-5", Decimal(string: "0.05")!),
    ])
    func readsDigitsAsCents(text: String, expected: Decimal) {
        #expect(CurrencyParser.amount(fromDigits: text) == expected)
    }

    @Test func truncatesAfterThirteenDigits() {
        #expect(CurrencyParser.amount(fromDigits: "99999999999999") == Decimal(string: "99999999999.99")!)
    }

    @Test func typingAndDeletingFollowsTheTypingEffect() {
        var text = CurrencyFormatter.string(from: 0)
        for digit in "125000" {
            text = CurrencyFormatter.string(from: CurrencyParser.amount(fromDigits: text + String(digit)))
        }
        #expect(text == "$ 1.250,00")

        for _ in 1...6 {
            text = CurrencyFormatter.string(from: CurrencyParser.amount(fromDigits: String(text.dropLast())))
        }
        #expect(text == "$ 0,00")
    }
}
