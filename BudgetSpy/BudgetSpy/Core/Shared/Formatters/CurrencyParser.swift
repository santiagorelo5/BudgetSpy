//
//  CurrencyParser.swift
//  BudgetSpy
//

import Foundation

/// Reads the digits typed in an amount field as cents; signs and other characters are ignored.
enum CurrencyParser {
    /// Up to `$ 99.999.999.999,99`.
    static let maximumDigits = 13

    static func amount(fromDigits text: String) -> Decimal {
        let digits = String(text.filter(\.isASCIIDigit).prefix(maximumDigits))
        guard let cents = Decimal(string: digits) else { return 0 }
        return cents / 100
    }
}

extension Character {
    var isASCIIDigit: Bool {
        ("0"..."9").contains(self)
    }
}
