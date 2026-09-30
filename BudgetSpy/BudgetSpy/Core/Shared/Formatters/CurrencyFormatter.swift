//
//  CurrencyFormatter.swift
//  BudgetSpy
//

import Foundation

/// Formats COP amounts as `$ 1.000,00` and `-$ 1.000,00`.
enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_CO")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "."
        formatter.groupingSize = 3
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "$ "
        formatter.negativePrefix = "-$ "
        return formatter
    }()

    static func string(from amount: Decimal) -> String {
        formatter.string(from: amount as NSDecimalNumber) ?? "$ 0,00"
    }

    private static let spokenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "."
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Text for VoiceOver, e.g. `menos 10.000 pesos` or `1.250 pesos con 50 centavos`.
    static func spokenString(from amount: Decimal) -> String {
        let magnitude = amount.magnitude
        var pesos = Decimal()
        var truncated = magnitude
        NSDecimalRound(&pesos, &truncated, 0, .down)
        let cents = (magnitude - pesos) * 100

        let sign = amount < 0 ? "menos " : ""
        let pesosText = spokenFormatter.string(from: pesos as NSDecimalNumber) ?? "0"
        let centsText = cents == 0 ? "" : " con \(cents) centavos"
        return "\(sign)\(pesosText) pesos\(centsText)"
    }
}
