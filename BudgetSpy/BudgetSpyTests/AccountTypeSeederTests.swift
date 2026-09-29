//
//  AccountTypeSeederTests.swift
//  BudgetSpyTests
//

import CoreData
import Testing
@testable import BudgetSpy

@MainActor
struct AccountTypeSeederTests {
    private func abbreviations(in context: NSManagedObjectContext) throws -> [String] {
        try fetchAll(AccountType.self, in: context).compactMap(\.abbreviation).sorted()
    }

    private func deleteAllAccountTypes(in context: NSManagedObjectContext) throws {
        try fetchAll(AccountType.self, in: context).forEach(context.delete)
        try context.save()
    }

    @Test func firstSeedCreatesSavingsAndCreditCard() throws {
        let context = makeInMemoryContext()
        try deleteAllAccountTypes(in: context)

        try AccountTypeSeeder.seed(in: context)

        #expect(try abbreviations(in: context) == ["CA", "TC"])
        let names = try fetchAll(AccountType.self, in: context).compactMap(\.name).sorted()
        #expect(names == ["Cuenta de Ahorros", "Tarjeta de Crédito"])
    }

    @Test func seedingThreeTimesKeepsTwoTypes() throws {
        let context = makeInMemoryContext()

        for _ in 1...3 {
            try AccountTypeSeeder.seed(in: context)
        }

        #expect(try abbreviations(in: context) == ["CA", "TC"])
    }

    @Test func seedingWithOnlySavingsCreatesOnlyCreditCard() throws {
        let context = makeInMemoryContext()
        let creditCard = try #require(try AccountType.find(.creditCard, in: context))
        let savingsID = try #require(try AccountType.find(.savings, in: context)).objectID
        context.delete(creditCard)
        try context.save()

        try AccountTypeSeeder.seed(in: context)

        #expect(try abbreviations(in: context) == ["CA", "TC"])
        #expect(try AccountType.find(.savings, in: context)?.objectID == savingsID)
    }
}
