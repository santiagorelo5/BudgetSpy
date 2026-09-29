//
//  AccountTypeListView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct AccountTypeListView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\AccountType.name, order: .forward)])
    private var accountTypes: FetchedResults<AccountType>

    var body: some View {
        List(accountTypes) { accountType in
            LabeledContent(accountType.name ?? "", value: accountType.abbreviation ?? "")
        }
        .navigationTitle("Tipos de cuenta")
    }
}

#Preview {
    NavigationStack {
        AccountTypeListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
