//
//  MovementDateFormatterTests.swift
//  BudgetSpyTests
//

import Foundation
import Testing
@testable import BudgetSpy

@MainActor
struct MovementDateFormatterTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test(arguments: [
        (2026, 9, 30, "30 sep 2026"),
        (2026, 1, 1, "1 ene 2026"),
        (2025, 12, 24, "24 dic 2025"),
    ])
    func formatsShortDate(year: Int, month: Int, day: Int, expected: String) {
        #expect(MovementDateFormatter.string(from: date(year, month, day)) == expected)
    }

    @Test func formatsSpokenDate() {
        #expect(MovementDateFormatter.spokenString(from: date(2026, 9, 30)) == "30 de septiembre de 2026")
    }
}
