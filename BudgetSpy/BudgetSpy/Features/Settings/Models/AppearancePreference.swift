//
//  AppearancePreference.swift
//  BudgetSpy
//

import SwiftUI

/// Appearance chosen by the user for the whole app.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// UserDefaults key shared by the reader (app root) and the writer (Settings).
    static let storageKey = "appearancePreference"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Oscuro"
        }
    }

    /// Color scheme to force, or `nil` to follow the system appearance.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
