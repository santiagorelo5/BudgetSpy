//
//  HomeView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var formRoute: AccountFormRoute?

    var body: some View {
        ScrollView {
            AccountCarouselView(context: context) { route in
                formRoute = route
            }
            .padding(.top)
        }
        .navigationDestination(item: $formRoute) { route in
            AccountFormView(route: route, context: context)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
