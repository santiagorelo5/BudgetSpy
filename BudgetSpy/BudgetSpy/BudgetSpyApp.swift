//
//  BudgetSpyApp.swift
//  BudgetSpy
//
//  Created by Santiago Restrepo lopez on 28/09/26.
//

import SwiftUI
import CoreData

@main
struct BudgetSpyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
