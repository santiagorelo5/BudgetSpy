//
//  AccountTypeSeeder.swift
//  BudgetSpy
//

import CoreData

/// Creates the seed account types that are missing, checking by abbreviation.
enum AccountTypeSeeder {
    static func seed(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<AccountType> = AccountType.fetchRequest()
        let existingAbbreviations = Set(try context.fetch(request).compactMap(\.abbreviation))
        let missingKinds = AccountKind.allCases.filter { !existingAbbreviations.contains($0.abbreviation) }
        guard !missingKinds.isEmpty else { return }

        for kind in missingKinds {
            let accountType = AccountType(context: context)
            accountType.name = kind.displayName
            accountType.abbreviation = kind.abbreviation
        }
        try context.save()
    }
}
