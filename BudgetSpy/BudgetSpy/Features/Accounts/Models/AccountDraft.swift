//
//  AccountDraft.swift
//  BudgetSpy
//

import Foundation

/// Values being edited in the account form.
struct AccountDraft: Equatable {
    var kind: AccountKind = .savings
    var name = ""
    var lastFourDigits = ""
    var balance: Decimal = 0
    var creditLimit: Decimal = 0
}

extension AccountDraft {
    init(account: Account) {
        self.init(
            kind: account.kind,
            name: account.name ?? "",
            lastFourDigits: account.lastFourDigits ?? "",
            balance: account.balanceValue,
            creditLimit: account.creditLimitValue ?? 0
        )
    }
}
