//
//  MovementLedger.swift
//  BudgetSpy
//

import CoreData

enum MovementLedgerError: Error, Equatable {
    case invalidMovement
    case balanceRuleViolated(MovementBalanceError)
    case deletionBlocked(MovementDeletionError)
    case missingMovementType(MovementKind)
}

/// The only place that writes account balances or creates, changes or deletes movements.
///
/// Every method validates with `MovementRules`, applies the effect on the context and does not
/// save: the caller saves once (or rolls back), so each operation is all or nothing.
final class MovementLedger {
    static let initialBalanceDescription = "Saldo inicial"
    static let adjustmentDescription = "Ajuste de saldo"

    private let context: NSManagedObjectContext
    private let rules: MovementRules

    init(context: NSManagedObjectContext, rules: MovementRules = MovementRules()) {
        self.context = context
        self.rules = rules
    }

    @discardableResult
    func create(_ draft: MovementDraft) throws -> Movement {
        guard let effect = MovementEffect(draft: draft) else { throw MovementLedgerError.invalidMovement }
        let accounts = try fetchAccounts(effect.accountIDs)
        try validate(effect, replacing: nil, accounts: accounts)

        let movement = Movement(context: context)
        movement.id = UUID()
        movement.createdAt = .now
        try assign(draft, effect: effect, to: movement, accounts: accounts)
        apply(effect, accounts: accounts, sign: 1)
        return movement
    }

    func update(_ movement: Movement, with draft: MovementDraft) throws {
        guard let oldEffect = movement.effect, let newEffect = MovementEffect(draft: draft) else {
            throw MovementLedgerError.invalidMovement
        }
        let accounts = try fetchAccounts(oldEffect.accountIDs + newEffect.accountIDs)
        try validate(newEffect, replacing: oldEffect, accounts: accounts)

        apply(oldEffect, accounts: accounts, sign: -1)
        try assign(draft, effect: newEffect, to: movement, accounts: accounts)
        apply(newEffect, accounts: accounts, sign: 1)
    }

    func delete(_ movement: Movement) throws {
        guard let effect = movement.effect else { throw MovementLedgerError.invalidMovement }
        let accounts = try fetchAccounts(effect.accountIDs)
        if let error = rules.deletionError(of: effect, accounts: snapshots(accounts)) {
            throw MovementLedgerError.deletionBlocked(error)
        }
        apply(effect, accounts: accounts, sign: -1)
        context.delete(movement)
    }

    /// Takes a new account (balance 0) to `balance` with a "Saldo inicial" movement dated on its creation.
    func recordInitialBalance(for account: Account, balance: Decimal) throws {
        let date = account.createdAt ?? .now
        try recordBalanceChange(for: account, to: balance, description: Self.initialBalanceDescription, date: date)
    }

    /// Takes an account to `newBalance` with an "Ajuste de saldo" movement dated today.
    func recordAdjustment(for account: Account, to newBalance: Decimal) throws {
        try recordBalanceChange(for: account, to: newBalance, description: Self.adjustmentDescription, date: .now)
    }

    /// Reclassifies the transfers of an account about to be deleted so that the other accounts
    /// keep their movements and balances. Expenses and incomes are removed by the cascade rule.
    func prepareDeletion(of account: Account) throws {
        let expenseType = try movementType(.expense)
        let incomeType = try movementType(.income)

        for movement in account.destinationMovementList {
            movement.movementType = expenseType
            movement.destinationAccount = nil
        }

        for movement in account.originMovementList where movement.kind == .transfer {
            guard let destination = movement.destinationAccount else { continue }
            movement.amountValue = rules.destinationSignedAmount(
                amount: movement.amountValue.magnitude,
                destinationKind: destination.kind
            )
            movement.originAccount = destination
            movement.destinationAccount = nil
            movement.movementType = incomeType
        }
    }

    private func recordBalanceChange(for account: Account, to newBalance: Decimal, description: String, date: Date) throws {
        guard let adjustment = rules.adjustment(for: account.kind, from: account.balanceValue, to: newBalance) else { return }

        let movement = Movement(context: context)
        movement.id = UUID()
        movement.createdAt = .now
        movement.date = Calendar.current.startOfDay(for: date)
        movement.movementDescription = description
        movement.amountValue = adjustment.signedAmount
        movement.movementType = try movementType(adjustment.kind)
        movement.originAccount = account
        account.balanceValue += adjustment.signedAmount
    }

    private func validate(_ effect: MovementEffect, replacing old: MovementEffect?, accounts: [UUID: Account]) throws {
        let snapshots = snapshots(accounts)
        guard rules.isAllowed(effect, accounts: snapshots) else { throw MovementLedgerError.invalidMovement }
        if let error = rules.balanceError(applying: effect, replacing: old, accounts: snapshots) {
            throw MovementLedgerError.balanceRuleViolated(error)
        }
    }

    private func assign(_ draft: MovementDraft, effect: MovementEffect, to movement: Movement, accounts: [UUID: Account]) throws {
        guard let origin = accounts[effect.originID] else { throw MovementLedgerError.invalidMovement }
        movement.movementType = try movementType(effect.kind)
        movement.movementDescription = draft.description
        movement.date = Calendar.current.startOfDay(for: draft.date)
        movement.amountValue = rules.signedAmount(of: effect.kind, amount: effect.amount, originKind: origin.kind)
        movement.originAccount = origin
        movement.destinationAccount = effect.destinationID.flatMap { accounts[$0] }
    }

    private func apply(_ effect: MovementEffect, accounts: [UUID: Account], sign: Decimal) {
        for (id, delta) in rules.deltas(of: effect, accounts: snapshots(accounts)) {
            accounts[id]?.balanceValue += sign * delta
        }
    }

    private func fetchAccounts(_ ids: [UUID]) throws -> [UUID: Account] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", Set(ids) as NSSet)
        let accounts = try context.fetch(request)
        return Dictionary(accounts.compactMap { account in account.id.map { ($0, account) } }, uniquingKeysWith: { first, _ in first })
    }

    private func snapshots(_ accounts: [UUID: Account]) -> MovementRules.Accounts {
        accounts.compactMapValues(AccountSnapshot.init(account:))
    }

    private func movementType(_ kind: MovementKind) throws -> MovementType {
        guard let movementType = try MovementType.find(kind, in: context) else {
            throw MovementLedgerError.missingMovementType(kind)
        }
        return movementType
    }
}
