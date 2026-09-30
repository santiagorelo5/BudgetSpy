//
//  MovementTypeSeederTests.swift
//  BudgetSpyTests
//

import CoreData
import Testing
@testable import BudgetSpy

@MainActor
struct MovementTypeSeederTests {
    private func names(in context: NSManagedObjectContext) throws -> [String] {
        try fetchAll(MovementType.self, in: context).compactMap(\.name).sorted()
    }

    @Test func firstSeedCreatesTheThreeTypes() throws {
        let context = makeInMemoryContext()
        try fetchAll(MovementType.self, in: context).forEach(context.delete)
        try context.save()

        try MovementTypeSeeder.seed(in: context)

        #expect(try names(in: context) == ["Gasto", "Ingreso", "Transferencia"])
    }

    @Test func seedingThreeTimesKeepsThreeTypes() throws {
        let context = makeInMemoryContext()

        for _ in 1...3 {
            try MovementTypeSeeder.seed(in: context)
        }

        #expect(try names(in: context) == ["Gasto", "Ingreso", "Transferencia"])
    }

    @Test func seedingWithTransferMissingCreatesOnlyTransfer() throws {
        let context = makeInMemoryContext()
        let expenseID = try #require(try MovementType.find(.expense, in: context)).objectID
        try context.delete(#require(try MovementType.find(.transfer, in: context)))
        try context.save()

        try MovementTypeSeeder.seed(in: context)

        #expect(try names(in: context) == ["Gasto", "Ingreso", "Transferencia"])
        #expect(try MovementType.find(.expense, in: context)?.objectID == expenseID)
    }
}
