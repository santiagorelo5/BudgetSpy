//
//  SettingsView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            NavigationLink("Datos Maestros") {
                MasterDataView()
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Apariencia")
                    Spacer()
                    appearanceSwitch
                }

                VStack(alignment: .leading) {
                    Text("Apariencia")
                    appearanceSwitch
                }
            }
        }
        .navigationTitle("Configuración")
    }

    /// Sun (off, light) and moon (on, dark) tell which side of the switch is which.
    private var appearanceSwitch: some View {
        HStack {
            Image(systemName: "sun.max.fill")
                .accessibilityHidden(true)
            Toggle("Apariencia, modo oscuro", isOn: isDarkMode)
                .labelsHidden()
            Image(systemName: "moon.fill")
                .accessibilityHidden(true)
        }
        .foregroundStyle(.secondary)
    }

    /// Reflects the appearance the app is shown with; flipping it saves the user's choice.
    private var isDarkMode: Binding<Bool> {
        Binding(
            get: { colorScheme == .dark },
            set: { appearance = AppearancePreference(isDarkMode: $0) }
        )
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
