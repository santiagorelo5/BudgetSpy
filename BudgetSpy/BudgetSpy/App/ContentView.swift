//
//  ContentView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var movementFormRoute: MovementFormRoute?

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Inicio", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView(movementFormRoute: $movementFormRoute)
                }
            }

            Tab(value: AppTab.newMovement) {
                EmptyView()
            } label: {
                Label("Agregar movimiento", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }

            Tab("Configuración", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }

    /// Selecting "+" opens the movement form on Home instead of switching to its tab.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                guard newTab == .newMovement else {
                    selectedTab = newTab
                    return
                }
                selectedTab = .home
                movementFormRoute = .create
            }
        )
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
