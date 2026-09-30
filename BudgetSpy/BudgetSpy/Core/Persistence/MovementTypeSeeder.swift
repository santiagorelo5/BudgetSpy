//
//  MovementTypeSeeder.swift
//  BudgetSpy
//

import CoreData

/// Creates the seed movement types that are missing, checking by name.
enum MovementTypeSeeder {
    static func seed(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<MovementType> = MovementType.fetchRequest()
        let existingNames = Set(try context.fetch(request).compactMap(\.name))
        let missingKinds = MovementKind.allCases.filter { !existingNames.contains($0.rawValue) }
        guard !missingKinds.isEmpty else { return }

        for kind in missingKinds {
            let movementType = MovementType(context: context)
            movementType.name = kind.rawValue
        }
        try context.save()
    }
}
