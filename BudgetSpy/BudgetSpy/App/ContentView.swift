//
//  ContentView.swift
//  BudgetSpy
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

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
    }
}

#Preview {
    ContentView()
}
