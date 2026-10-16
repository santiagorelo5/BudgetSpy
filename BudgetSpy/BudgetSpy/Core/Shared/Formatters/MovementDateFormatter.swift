//
//  MovementDateFormatter.swift
//  BudgetSpy
//

import Foundation

/// Formats a movement date as `30 sep 2026` and, for VoiceOver, as `30 de septiembre de 2026`.
enum MovementDateFormatter {
    /// Fixed because the Spanish ICU data abbreviates September as "sept.".
    private static let monthAbbreviations = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]

    private static let spokenFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_CO")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static func string(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        guard let day = components.day, let month = components.month, let year = components.year else { return "" }
        return "\(day) \(monthAbbreviations[month - 1]) \(year)"
    }

    static func spokenString(from date: Date) -> String {
        spokenFormatter.string(from: date)
    }
}
