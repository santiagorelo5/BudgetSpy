//
//  SettingsView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system

    var body: some View {
        List {
            NavigationLink("Datos Maestros") {
                MasterDataView()
            }

            Picker("Apariencia", selection: $appearance) {
                ForEach(AppearancePreference.allCases) { preference in
                    Text(preference.displayName).tag(preference)
                }
            }
            .pickerStyle(.menu)
        }
        .navigationTitle("Configuración")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Oscuro") {
    NavigationStack {
        SettingsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .preferredColorScheme(.dark)
}
