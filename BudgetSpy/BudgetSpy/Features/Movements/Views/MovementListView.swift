//
//  MovementListView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

/// "Movimientos" section of Home: every movement of one account, newest first,
/// in an area with the fixed height of 6 rows whatever the number of movements.
struct MovementListView: View {
    private static let visibleRowCount: CGFloat = 6

    @FetchRequest private var movements: FetchedResults<Movement>
    @State private var viewModel: MovementListViewModel
    @State private var movementInDetail: Movement?
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 73
    private let account: Account
    private let onCreate: () -> Void
    private let onEdit: (Movement) -> Void

    init(
        account: Account,
        context: NSManagedObjectContext,
        onCreate: @escaping () -> Void,
        onEdit: @escaping (Movement) -> Void
    ) {
        _movements = FetchRequest(
            // `date` has only the day; `createdAt` breaks ties with the time.
            sortDescriptors: [
                SortDescriptor(\Movement.date, order: .reverse),
                SortDescriptor(\Movement.createdAt, order: .reverse),
            ],
            predicate: NSPredicate(format: "originAccount == %@ OR destinationAccount == %@", account, account)
        )
        _viewModel = State(initialValue: MovementListViewModel(context: context))
        self.account = account
        self.onCreate = onCreate
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            Group {
                if movements.isEmpty {
                    Text("Sin movimientos")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    list
                }
            }
            .frame(height: rowHeight * Self.visibleRowCount)
        }
        .confirmationDialog(
            viewModel.deletionConfirmationTitle,
            isPresented: $viewModel.deletionConfirmationIsPresented,
            titleVisibility: .visible,
            presenting: viewModel.movementPendingDeletion
        ) { movement in
            Button("Eliminar movimiento", role: .destructive) {
                viewModel.confirmDeletion(of: movement)
            }
            Button("Cancelar", role: .cancel) {
                viewModel.cancelDeletion()
            }
        } message: { _ in
            Text("Esta acción no se puede deshacer.")
        }
        .alert(viewModel.blockedDeletionMessage ?? "", isPresented: $viewModel.blockedDeletionIsPresented) {
            Button("Aceptar", role: .cancel) {}
        }
        .alert("No se pudo eliminar el movimiento. Intenta de nuevo.", isPresented: $viewModel.deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Text("Movimientos")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button("Agregar movimiento", systemImage: "plus.circle.fill", action: onCreate)
                .labelStyle(.iconOnly)
                .font(.title2)
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                .contentShape(.rect)
        }
        .padding(.horizontal)
    }

    private var list: some View {
        List(movements) { movement in
            MovementRowView(content: MovementRowContent(movement: movement, perspective: account))
                .contentShape(.rect)
                .onLongPressGesture {
                    movementInDetail = movement
                }
                .popover(isPresented: detailIsPresented(for: movement)) {
                    MovementDetailView(movement: movement, perspective: account)
                        .presentationCompactAdaptation(.popover)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    // Not `.destructive`: the list would remove the row before the confirmation.
                    Button("Eliminar", systemImage: "trash") {
                        viewModel.requestDeletion(of: movement)
                    }
                    .tint(.red)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button("Editar", systemImage: "pencil") {
                        onEdit(movement)
                    }
                    .tint(.blue)
                }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, rowHeight)
    }

    private func detailIsPresented(for movement: Movement) -> Binding<Bool> {
        Binding(
            get: { movementInDetail == movement },
            set: { isPresented in
                if !isPresented {
                    movementInDetail = nil
                }
            }
        )
    }
}

#Preview("Con 10 movimientos") {
    let (account, context) = previewAccountWithTenMovements()

    MovementListView(account: account, context: context, onCreate: {}, onEdit: { _ in })
        .environment(\.managedObjectContext, context)
}

#Preview("Sin movimientos") {
    let context = PersistenceController(inMemory: true).container.viewContext
    let account = Account(context: context)

    MovementListView(account: account, context: context, onCreate: {}, onEdit: { _ in })
        .environment(\.managedObjectContext, context)
}

/// A savings account with an initial balance and 9 more movements over the last days.
private func previewAccountWithTenMovements() -> (Account, NSManagedObjectContext) {
    let context = PersistenceController(inMemory: true).container.viewContext
    let account = Account(context: context)
    account.id = UUID()
    account.name = "Nómina"
    account.lastFourDigits = "4821"
    account.createdAt = Calendar.current.date(byAdding: .day, value: -10, to: .now)
    account.accountType = try? AccountType.find(.savings, in: context)

    let ledger = MovementLedger(context: context)
    try? ledger.recordInitialBalance(for: account, balance: 2_000_000)
    for day in 1...9 {
        let kind: MovementKind = day.isMultiple(of: 3) ? .income : .expense
        try? ledger.create(MovementDraft(
            kind: kind,
            amount: Decimal(day * 15_000),
            description: kind == .income ? "Reembolso \(day)" : "Compra \(day)",
            date: Calendar.current.date(byAdding: .day, value: -day, to: .now) ?? .now,
            originAccountID: account.id
        ))
    }
    return (account, context)
}
