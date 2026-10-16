//
//  AppearancePreference.swift
//  BudgetSpy
//

import SwiftUI

/// Appearance chosen by the user for the whole app.
enum AppearancePreference: String, CaseIterable, Identifiable {
    /// No choice saved yet: the app follows the system appearance.
    case system
    case light
    case dark

    /// UserDefaults key shared by the reader (app root) and the writer (Settings).
    static let storageKey = "appearancePreference"

    /// Preference saved when the user flips the dark mode switch.
    init(isDarkMode: Bool) {
        self = isDarkMode ? .dark : .light
    }

    var id: String { rawValue }

    /// Color scheme to force, or `nil` to follow the system appearance.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
