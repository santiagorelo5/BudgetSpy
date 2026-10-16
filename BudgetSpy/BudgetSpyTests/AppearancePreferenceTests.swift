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

    @Test func darkModeSwitchOnSavesDark() {
        #expect(AppearancePreference(isDarkMode: true) == .dark)
    }

    @Test func darkModeSwitchOffSavesLight() {
        #expect(AppearancePreference(isDarkMode: false) == .light)
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
