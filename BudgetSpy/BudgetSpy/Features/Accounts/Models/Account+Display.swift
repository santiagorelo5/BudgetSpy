//
//  Account+Display.swift
//  BudgetSpy
//

import CoreData

extension AccountType {
    var kind: AccountKind? {
        abbreviation.flatMap(AccountKind.init(rawValue:))
    }

    static func find(_ kind: AccountKind, in context: NSManagedObjectContext) throws -> AccountType? {
        let request: NSFetchRequest<AccountType> = AccountType.fetchRequest()
        request.predicate = NSPredicate(format: "abbreviation == %@", kind.abbreviation)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

extension Account {
    var kind: AccountKind {
        accountType?.kind ?? .savings
    }

    var balanceValue: Decimal {
        get { balance?.decimalValue ?? 0 }
        set { balance = NSDecimalNumber(decimal: newValue) }
    }

    var creditLimitValue: Decimal? {
        get { creditLimit?.decimalValue }
        set { creditLimit = newValue.map { NSDecimalNumber(decimal: $0) } }
    }
}
