//
//  AccountCarouselView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct AccountCarouselView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Account.createdAt, order: .forward)])
    private var accounts: FetchedResults<Account>
    @State private var viewModel: AccountCarouselViewModel
    private let openForm: (AccountFormRoute) -> Void

    init(context: NSManagedObjectContext, openForm: @escaping (AccountFormRoute) -> Void) {
        _viewModel = State(initialValue: AccountCarouselViewModel(context: context))
        self.openForm = openForm
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(accounts) { account in
                    AccountCardView(content: AccountCardContent(account: account))
                        .containerRelativeFrame(.horizontal) { length, _ in length * 0.85 }
                        .contentShape(.contextMenuPreview, .rect(cornerRadius: AccountCardView.cornerRadius))
                        .contextMenu {
                            Button("Editar", systemImage: "pencil") {
                                openForm(.edit(account))
                            }
                            Button("Eliminar", systemImage: "trash", role: .destructive) {
                                viewModel.requestDeletion(of: account)
                            }
                        }
                }

                AddAccountCardView {
                    openForm(.create)
                }
                .containerRelativeFrame(.horizontal) { length, _ in length * 0.85 }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .confirmationDialog(
            viewModel.deletionConfirmationTitle,
            isPresented: $viewModel.deletionConfirmationIsPresented,
            titleVisibility: .visible,
            presenting: viewModel.accountPendingDeletion
        ) { account in
            Button("Eliminar cuenta", role: .destructive) {
                viewModel.confirmDeletion(of: account)
            }
            Button("Cancelar", role: .cancel) {
                viewModel.cancelDeletion()
            }
        } message: { _ in
            Text("Esta acción no se puede deshacer.")
        }
        .alert("No se pudo eliminar la cuenta. Intenta de nuevo.", isPresented: $viewModel.deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) {}
        }
    }
}

#Preview("Con cuentas") {
    let context = PersistenceController.preview.container.viewContext

    AccountCarouselView(context: context) { _ in }
        .environment(\.managedObjectContext, context)
}

#Preview("Sin cuentas") {
    let context = PersistenceController(inMemory: true).container.viewContext

    AccountCarouselView(context: context) { _ in }
        .environment(\.managedObjectContext, context)
}
