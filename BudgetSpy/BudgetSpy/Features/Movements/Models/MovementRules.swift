//
//  MovementRules.swift
//  BudgetSpy
//

import Foundation

/// Sign, effect and validation of movements over account balances.
///
/// The signed amount of a movement for an account is exactly the change it causes in that
/// account's stored balance (saldo for savings, debt for credit cards).
struct MovementRules {
    typealias Accounts = [UUID: AccountSnapshot]

    /// Signed amount as seen from the origin account.
    func signedAmount(of kind: MovementKind, amount: Decimal, originKind: AccountKind) -> Decimal {
        switch (kind, originKind) {
        case (.expense, .savings), (.transfer, _), (.income, .creditCard): -amount
        case (.expense, .creditCard), (.income, .savings): amount
        }
    }

    /// Signed amount of a transfer as seen from its destination account.
    func destinationSignedAmount(amount: Decimal, destinationKind: AccountKind) -> Decimal {
        destinationKind == .savings ? amount : -amount
    }

    /// Whether the movement is well formed: positive amount, known accounts, and for transfers
    /// a savings origin and a different destination.
    func isAllowed(_ effect: MovementEffect, accounts: Accounts) -> Bool {
        guard effect.amount > 0, let origin = accounts[effect.originID] else { return false }
        guard effect.kind == .transfer else { return effect.destinationID == nil }
        guard origin.kind == .savings,
              let destinationID = effect.destinationID,
              destinationID != effect.originID else { return false }
        return accounts[destinationID] != nil
    }

    /// Change the movement causes in each account it touches.
    func deltas(of effect: MovementEffect, accounts: Accounts) -> [UUID: Decimal] {
        guard let origin = accounts[effect.originID] else { return [:] }
        var deltas = [effect.originID: signedAmount(of: effect.kind, amount: effect.amount, originKind: origin.kind)]
        if effect.kind == .transfer, let destinationID = effect.destinationID, let destination = accounts[destinationID] {
            deltas[destinationID] = destinationSignedAmount(amount: effect.amount, destinationKind: destination.kind)
        }
        return deltas
    }

    /// Reverts `old` (when editing), applies `new` and checks every touched account,
    /// the new origin first, then the new destination, then the accounts only `old` touched.
    func balanceError(applying new: MovementEffect, replacing old: MovementEffect? = nil, accounts: Accounts) -> MovementBalanceError? {
        let reverted = balances(accounts, adding: old.map { deltas(of: $0, accounts: accounts) }, sign: -1)
        let result = balances(reverted, adding: deltas(of: new, accounts: accounts), sign: 1)
        let touchedIDs = new.accountIDs + (old?.accountIDs ?? []).filter { !new.accountIDs.contains($0) }

        for id in touchedIDs {
            guard let account = accounts[id], let before = reverted[id], let after = result[id] else { continue }
            if let error = balanceError(for: account, before: before, after: after) {
                return error
            }
        }
        return nil
    }

    /// Checks that reverting the movement leaves every touched account valid.
    func deletionError(of effect: MovementEffect, accounts: Accounts) -> MovementDeletionError? {
        let result = balances(accounts.mapValues(\.balance), adding: deltas(of: effect, accounts: accounts), sign: -1)
        for id in effect.accountIDs {
            guard let account = accounts[id], let after = result[id] else { continue }
            switch account.kind {
            case .savings where after < 0:
                return .savingsBelowZero(accountName: account.name, resultingBalance: after)
            case .creditCard where after < 0:
                return .debtBelowZero(accountName: account.name, resultingDebt: after)
            case .creditCard where after > (account.creditLimit ?? 0):
                return .debtAboveLimit(accountName: account.name, resultingDebt: after, creditLimit: account.creditLimit ?? 0)
            default:
                continue
            }
        }
        return nil
    }

    /// Movement that takes an account's balance from `old` to `new`: an income when the saldo goes
    /// up or the debt goes down, an expense otherwise. `nil` when the balance does not change.
    func adjustment(for accountKind: AccountKind, from old: Decimal, to new: Decimal) -> (kind: MovementKind, signedAmount: Decimal)? {
        let delta = new - old
        guard delta != 0 else { return nil }
        let increasesMoney = accountKind == .savings ? delta > 0 : delta < 0
        return (increasesMoney ? .income : .expense, delta)
    }

    private func balances(_ accounts: Accounts, adding deltas: [UUID: Decimal]?, sign: Decimal) -> [UUID: Decimal] {
        balances(accounts.mapValues(\.balance), adding: deltas, sign: sign)
    }

    private func balances(_ balances: [UUID: Decimal], adding deltas: [UUID: Decimal]?, sign: Decimal) -> [UUID: Decimal] {
        var result = balances
        for (id, delta) in deltas ?? [:] {
            result[id, default: 0] += sign * delta
        }
        return result
    }

    private func balanceError(for account: AccountSnapshot, before: Decimal, after: Decimal) -> MovementBalanceError? {
        switch account.kind {
        case .savings where after < 0:
            return .insufficientFunds(accountName: account.name, available: before)
        case .creditCard where after < 0:
            return .exceedsDebt(accountName: account.name, debt: before)
        case .creditCard where after > (account.creditLimit ?? 0):
            return .exceedsCreditLimit(accountName: account.name, availableCredit: (account.creditLimit ?? 0) - before)
        default:
            return nil
        }
    }
}
