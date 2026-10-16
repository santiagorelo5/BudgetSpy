//
//  AppearancePreferenceTests.swift
//  BudgetSpyTests
//

import SwiftUI
import Testing
@testable import BudgetSpy

@MainActor
struct AppearancePreferenceTests {
    @Test func colorSchemes() {
        #expect(AppearancePreference.system.colorScheme == nil)
        #expect(AppearancePreference.light.colorScheme == .light)
        #expect(AppearancePreference.dark.colorScheme == .dark)
    }

    @Test func displayNames() {
        #expect(AppearancePreference.system.displayName == "Sistema")
        #expect(AppearancePreference.light.displayName == "Claro")
        #expect(AppearancePreference.dark.displayName == "Oscuro")
    }

    @Test func pickerOrder() {
        #expect(AppearancePreference.allCases == [.system, .light, .dark])
    }

    @Test func stableRawValues() {
        #expect(AppearancePreference.system.rawValue == "system")
        #expect(AppearancePreference.light.rawValue == "light")
        #expect(AppearancePreference.dark.rawValue == "dark")
    }

    @Test func unknownRawValueIsNil() {
        #expect(AppearancePreference(rawValue: "otro") == nil)
    }
}
