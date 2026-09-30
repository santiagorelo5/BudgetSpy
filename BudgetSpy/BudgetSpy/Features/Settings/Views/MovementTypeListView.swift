//
//  MovementTypeListView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct MovementTypeListView: View {
    // Alphabetical order matches the required order: Gasto, Ingreso, Transferencia.
    @FetchRequest(sortDescriptors: [SortDescriptor(\MovementType.name, order: .forward)])
    private var movementTypes: FetchedResults<MovementType>

    var body: some View {
        List(movementTypes) { movementType in
            Text(movementType.name ?? "")
        }
        .navigationTitle("Tipos de movimiento")
    }
}

#Preview {
    NavigationStack {
        MovementTypeListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
