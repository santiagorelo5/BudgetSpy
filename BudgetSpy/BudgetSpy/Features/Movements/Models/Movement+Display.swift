//
//  Movement+Display.swift
//  BudgetSpy
//

import CoreData

extension MovementType {
    var kind: MovementKind? {
        name.flatMap(MovementKind.init(rawValue:))
    }

    static func find(_ kind: MovementKind, in context: NSManagedObjectContext) throws -> MovementType? {
        let request: NSFetchRequest<MovementType> = MovementType.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", kind.rawValue)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

extension Movement {
    /// Signed as seen from the origin account.
    var amountValue: Decimal {
        get { amount?.decimalValue ?? 0 }
        set { amount = NSDecimalNumber(decimal: newValue) }
    }

    var kind: MovementKind {
        movementType?.kind ?? .expense
    }

    var effect: MovementEffect? {
        guard let originID = originAccount?.id else { return nil }
        return MovementEffect(
            kind: kind,
            amount: amountValue.magnitude,
            originID: originID,
            destinationID: destinationAccount?.id
        )
    }

    /// Signed amount as seen from `account`, which is the origin or the destination.
    func signedAmount(for account: Account, rules: MovementRules = MovementRules()) -> Decimal {
        guard account != originAccount, account == destinationAccount else { return amountValue }
        return rules.destinationSignedAmount(amount: amountValue.magnitude, destinationKind: account.kind)
    }
}

extension Account {
    var originMovementList: [Movement] {
        (originMovements as? Set<Movement>).map(Array.init) ?? []
    }

    var destinationMovementList: [Movement] {
        (destinationMovements as? Set<Movement>).map(Array.init) ?? []
    }
}
