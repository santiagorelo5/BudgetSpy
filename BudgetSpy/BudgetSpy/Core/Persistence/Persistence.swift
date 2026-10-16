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
            try insertSampleData(in: result.container.viewContext)
        } catch {
            logger.error("No se pudieron crear los datos de ejemplo: \(error)")
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

        do {
            try MovementTypeSeeder.seed(in: container.viewContext)
        } catch {
            Self.logger.error("No se pudieron crear los tipos de movimiento: \(error)")
        }
    }

    private static func insertSampleData(in context: NSManagedObjectContext) throws {
        guard let savings = try AccountType.find(.savings, in: context),
              let creditCard = try AccountType.find(.creditCard, in: context) else { return }
        let ledger = MovementLedger(context: context)

        let payroll = Account(context: context)
        payroll.id = UUID()
        payroll.name = "Nómina Bancolombia"
        payroll.lastFourDigits = "4821"
        payroll.createdAt = .now.addingTimeInterval(-60)
        payroll.accountType = savings
        try ledger.recordInitialBalance(for: payroll, balance: 1_250_000)

        let visa = Account(context: context)
        visa.id = UUID()
        visa.name = "Visa"
        visa.lastFourDigits = "1234"
        visa.creditLimitValue = 5_000_000
        visa.createdAt = .now
        visa.accountType = creditCard
        try ledger.recordInitialBalance(for: visa, balance: 1_200_000)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        let samples: [MovementDraft] = [
            MovementDraft(kind: .expense, amount: 10_000, description: "Compra de café", date: .now, originAccountID: payroll.id),
            MovementDraft(kind: .income, amount: 350_000, description: "Pago freelance", date: yesterday, originAccountID: payroll.id),
            MovementDraft(kind: .transfer, amount: 200_000, description: "Pago tarjeta", date: yesterday,
                          originAccountID: payroll.id, destinationAccountID: visa.id),
            MovementDraft(kind: .expense, amount: 85_000, description: "Mercado", date: .now, originAccountID: visa.id),
        ]
        for draft in samples {
            try ledger.create(draft)
        }

        try context.save()
    }
}
