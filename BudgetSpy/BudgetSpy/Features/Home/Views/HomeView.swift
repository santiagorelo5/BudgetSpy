//
//  HomeView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\Account.createdAt, order: .forward)])
    private var accounts: FetchedResults<Account>
    @Binding var movementFormRoute: MovementFormRoute?
    @State private var accountFormRoute: AccountFormRoute?
    @State private var focusedAccountID: UUID?

    var body: some View {
        // No outer vertical scroll: the movement list is the only vertical scroll of Home.
        VStack(alignment: .leading, spacing: 20) {
            AccountCarouselView(context: context, focusedAccountID: $focusedAccountID) { route in
                accountFormRoute = route
            }

            if let focusedAccount {
                MovementListView(account: focusedAccount, context: context) { movement in
                    movementFormRoute = .edit(movement)
                }
                .id(focusedAccount.objectID)
            }

            Spacer(minLength: 0)
        }
        .padding(.top)
        .navigationDestination(item: $accountFormRoute) { route in
            AccountFormView(route: route, context: context)
        }
        .navigationDestination(item: $movementFormRoute) { route in
            MovementFormView(route: route, context: context) { originAccountID in
                focusedAccountID = originAccountID
            }
        }
    }

    private var focusedAccount: Account? {
        accounts.first { $0.id != nil && $0.id == focusedAccountID }
    }
}

#Preview {
    @Previewable @State var movementFormRoute: MovementFormRoute?

    NavigationStack {
        HomeView(movementFormRoute: $movementFormRoute)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
