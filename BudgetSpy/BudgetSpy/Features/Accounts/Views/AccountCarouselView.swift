//
//  AccountCarouselView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct AccountCarouselView: View {
    /// Identity of each card, so the "+" card can be focused too.
    private enum CardID: Hashable {
        case account(UUID)
        case add
    }

    @FetchRequest(sortDescriptors: [SortDescriptor(\Account.createdAt, order: .forward)])
    private var accounts: FetchedResults<Account>
    @State private var viewModel: AccountCarouselViewModel
    /// `nil` until the carousel places itself on its first card.
    @State private var position: CardID?
    /// The account whose card is focused; `nil` when the "+" card is.
    @Binding private var focusedAccountID: UUID?
    private let openForm: (AccountFormRoute) -> Void

    init(context: NSManagedObjectContext, focusedAccountID: Binding<UUID?>, openForm: @escaping (AccountFormRoute) -> Void) {
        _viewModel = State(initialValue: AccountCarouselViewModel(context: context))
        _focusedAccountID = focusedAccountID
        self.openForm = openForm
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(accounts) { account in
                    AccountCardView(content: AccountCardContent(account: account))
                        .containerRelativeFrame(.horizontal) { length, _ in length * 0.85 }
                        .id(cardID(of: account))
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
                .id(CardID.add)
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $position)
        .onAppear { placeFocus() }
        .onChange(of: accounts.compactMap(\.id)) { oldIDs, _ in placeFocus(previousIDs: oldIDs) }
        .onChange(of: position) { _, newPosition in
            if case .account(let id) = newPosition {
                focusedAccountID = id
            } else {
                focusedAccountID = nil
            }
        }
        .onChange(of: focusedAccountID) { _, newID in
            guard let newID, position != .account(newID) else { return }
            withAnimation {
                position = .account(newID)
            }
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

    private func cardID(of account: Account) -> CardID {
        account.id.map(CardID.account) ?? .add
    }

    /// Focuses the first account when the carousel starts or when the focused account disappears,
    /// and a newly created account when the "+" card was focused.
    private func placeFocus(previousIDs: [UUID]? = nil) {
        let ids = accounts.compactMap(\.id)
        switch position {
        case .add:
            if let previousIDs, let addedID = ids.first(where: { !previousIDs.contains($0) }) {
                position = .account(addedID)
            }
        case .account(let id) where ids.contains(id):
            return
        default:
            position = ids.first.map(CardID.account) ?? .add
        }
    }
}

#Preview("Con cuentas") {
    @Previewable @State var focusedAccountID: UUID?
    let context = PersistenceController.preview.container.viewContext

    VStack {
        AccountCarouselView(context: context, focusedAccountID: $focusedAccountID) { _ in }
        Text("Enfocada: \(focusedAccountID?.uuidString.prefix(8) ?? "tarjeta +")")
    }
    .environment(\.managedObjectContext, context)
}

#Preview("Sin cuentas") {
    @Previewable @State var focusedAccountID: UUID?
    let context = PersistenceController(inMemory: true).container.viewContext

    AccountCarouselView(context: context, focusedAccountID: $focusedAccountID) { _ in }
        .environment(\.managedObjectContext, context)
}
