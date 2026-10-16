//
//  ContentView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Inicio", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Configuración", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
