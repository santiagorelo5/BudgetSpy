//
//  MovementRowContent.swift
//  BudgetSpy
//

import Foundation

/// What a movement row or detail shows, as seen from one of its accounts.
struct MovementRowContent: Equatable {
    /// Money leaving the account is red; money entering it is green.
    enum Role: Equatable {
        case outgoing
        case incoming
    }

    let kind: MovementKind
    let description: String
    let date: Date
    let signedAmount: Decimal
    let role: Role

    var systemImage: String { kind.systemImage }

    var formattedDate: String {
        MovementDateFormatter.string(from: date)
    }

    var formattedAmount: String {
        CurrencyFormatter.string(from: signedAmount)
    }

    var accessibilityLabel: String {
        [
            kind.displayName,
            description,
            MovementDateFormatter.spokenString(from: date),
            CurrencyFormatter.spokenString(from: signedAmount),
        ].joined(separator: ", ")
    }
}

extension MovementRowContent {
    init(movement: Movement, perspective account: Account) {
        let isOrigin = movement.originAccount == account
        let role: Role = switch movement.kind {
        case .expense: .outgoing
        case .income: .incoming
        case .transfer: isOrigin ? .outgoing : .incoming
        }
        self.init(
            kind: movement.kind,
            description: movement.movementDescription ?? "",
            date: movement.date ?? .now,
            signedAmount: movement.signedAmount(for: account),
            role: role
        )
    }
}
