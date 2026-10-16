//
//  TestSupport.swift
//  BudgetSpyTests
//

import CoreData
@testable import BudgetSpy

@MainActor
func makeInMemoryContext() -> NSManagedObjectContext {
    PersistenceController(inMemory: true).container.viewContext
}

@MainActor
func fetchAll<T: NSManagedObject>(_ type: T.Type, in context: NSManagedObjectContext) throws -> [T] {
    try context.fetch(NSFetchRequest<T>(entityName: String(describing: type)))
}

/// Inserts an account whose balance comes from a "Saldo inicial" movement, so balances and movements add up.
@MainActor
@discardableResult
func insertAccount(
    _ name: String,
    kind: AccountKind = .savings,
    balance: Decimal = 0,
    creditLimit: Decimal? = nil,
    createdAt: Date = .now,
    in context: NSManagedObjectContext
) throws -> Account {
    let account = Account(context: context)
    account.id = UUID()
    account.name = name
    account.lastFourDigits = "1234"
    account.createdAt = createdAt
    account.creditLimitValue = kind.requiresCreditLimit ? (creditLimit ?? 5_000_000) : nil
    account.accountType = try AccountType.find(kind, in: context)
    try MovementLedger(context: context).recordInitialBalance(for: account, balance: balance)
    try context.save()
    return account
}

/// Sum of the signed amounts every movement causes on `account`.
@MainActor
func movementTotal(of account: Account) -> Decimal {
    (account.originMovementList + account.destinationMovementList)
        .reduce(Decimal(0)) { $0 + $1.signedAmount(for: account) }
}
