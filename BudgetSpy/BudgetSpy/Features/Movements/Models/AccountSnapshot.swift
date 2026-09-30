//
//  AccountSnapshot.swift
//  BudgetSpy
//

import Foundation

/// Values of an account that the balance rules need, detached from Core Data.
struct AccountSnapshot: Equatable, Identifiable {
    let id: UUID
    let kind: AccountKind
    let name: String
    let balance: Decimal
    let creditLimit: Decimal?
}

extension AccountSnapshot {
    init?(account: Account) {
        guard let id = account.id else { return nil }
        self.init(
            id: id,
            kind: account.kind,
            name: account.name ?? "",
            balance: account.balanceValue,
            creditLimit: account.creditLimitValue
        )
    }
}
