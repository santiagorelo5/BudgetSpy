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
