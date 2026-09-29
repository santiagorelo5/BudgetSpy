//
//  MasterDataView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct MasterDataView: View {
    var body: some View {
        List {
            NavigationLink("Tipos de cuenta") {
                AccountTypeListView()
            }
        }
        .navigationTitle("Datos Maestros")
    }
}

#Preview {
    NavigationStack {
        MasterDataView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
