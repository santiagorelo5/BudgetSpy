//
//  AccountKind.swift
//  BudgetSpy
//

/// Behavior of an account type, resolved from its abbreviation.
enum AccountKind: String, CaseIterable, Identifiable {
    case savings = "CA"
    case creditCard = "TC"

    var id: String { rawValue }

    var abbreviation: String { rawValue }

    var displayName: String {
        switch self {
        case .savings: "Cuenta de Ahorros"
        case .creditCard: "Tarjeta de Crédito"
        }
    }

    var balanceTitle: String {
        switch self {
        case .savings: "Saldo disponible"
        case .creditCard: "Deuda a la fecha"
        }
    }

    /// Word used by VoiceOver before the balance.
    var balanceSpokenName: String {
        switch self {
        case .savings: "saldo"
        case .creditCard: "deuda"
        }
    }

    var requiresCreditLimit: Bool {
        self == .creditCard
    }
}
