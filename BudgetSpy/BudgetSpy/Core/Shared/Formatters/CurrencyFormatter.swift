//
//  CurrencyFormatter.swift
//  BudgetSpy
//

import Foundation

/// Formats COP amounts as `$ 1.000,00` and `$ -1.000,00`.
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
        formatter.negativePrefix = "$ -"
        return formatter
    }()

    static func string(from amount: Decimal) -> String {
        formatter.string(from: amount as NSDecimalNumber) ?? "$ 0,00"
    }
}
