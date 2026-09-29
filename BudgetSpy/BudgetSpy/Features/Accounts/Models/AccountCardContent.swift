//
//  AccountCardContent.swift
//  BudgetSpy
//

import Foundation

/// What an account card shows, whether it comes from a saved account or from the form draft.
struct AccountCardContent: Equatable {
    static let namePlaceholder = "Nombre de la cuenta"
    private static let digitPlaceholder: Character = "-"

    let kind: AccountKind
    let name: String
    let lastFourDigits: String
    let balance: Decimal

    var isNamePlaceholder: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayedName: String {
        isNamePlaceholder ? Self.namePlaceholder : name
    }

    var maskedLastFourDigits: String {
        "**** " + paddedLastFourDigits
    }

    var formattedBalance: String {
        CurrencyFormatter.string(from: balance)
    }

    var accessibilityLabel: String {
        "\(kind.displayName), \(displayedName), terminada en \(lastFourDigits), \(kind.balanceSpokenName) \(formattedBalance)"
    }

    private var paddedLastFourDigits: String {
        let missingCount = max(AccountValidator.lastFourDigitsLength - lastFourDigits.count, 0)
        return lastFourDigits + String(repeating: Self.digitPlaceholder, count: missingCount)
    }
}

extension AccountCardContent {
    init(draft: AccountDraft) {
        self.init(kind: draft.kind, name: draft.name, lastFourDigits: draft.lastFourDigits, balance: draft.balance)
    }

    init(account: Account) {
        self.init(
            kind: account.kind,
            name: account.name ?? "",
            lastFourDigits: account.lastFourDigits ?? "",
            balance: account.balanceValue
        )
    }
}
