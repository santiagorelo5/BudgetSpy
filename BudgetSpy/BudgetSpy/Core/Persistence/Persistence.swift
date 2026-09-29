//
//  Persistence.swift
//  BudgetSpy
//
//  Created by Santiago Restrepo lopez on 28/09/26.
//

import CoreData
import OSLog

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        do {
            try insertSampleAccounts(in: result.container.viewContext)
        } catch {
            logger.error("No se pudieron crear las cuentas de ejemplo: \(error)")
        }
        return result
    }()

    private static let logger = Logger(subsystem: "BudgetSpy", category: "Persistence")

    /// Loaded once so that several containers (previews, tests) share the same entity descriptions.
    private static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "BudgetSpy", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("No se encontró el modelo de datos BudgetSpy")
        }
        return model
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BudgetSpy", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                Self.logger.fault("No se pudo cargar el almacenamiento: \(error)")
                fatalError("No se pudo cargar el almacenamiento: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true

        do {
            try AccountTypeSeeder.seed(in: container.viewContext)
        } catch {
            Self.logger.error("No se pudieron crear los tipos de cuenta: \(error)")
        }
    }

    private static func insertSampleAccounts(in context: NSManagedObjectContext) throws {
        guard let savings = try AccountType.find(.savings, in: context),
              let creditCard = try AccountType.find(.creditCard, in: context) else { return }

        let payroll = Account(context: context)
        payroll.id = UUID()
        payroll.name = "Nómina Bancolombia"
        payroll.lastFourDigits = "4821"
        payroll.balanceValue = 1_250_000
        payroll.createdAt = .now.addingTimeInterval(-60)
        payroll.accountType = savings

        let visa = Account(context: context)
        visa.id = UUID()
        visa.name = "Visa"
        visa.lastFourDigits = "1234"
        visa.balanceValue = 1_200_000
        visa.creditLimitValue = 5_000_000
        visa.createdAt = .now
        visa.accountType = creditCard

        try context.save()
    }
}
