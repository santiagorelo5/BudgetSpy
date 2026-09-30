//
//  MovementFormView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct MovementFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MovementFormViewModel
    // Typed text is kept here so the field is rewritten when the view model truncates it.
    @State private var description: String
    @State private var discardConfirmationIsPresented = false
    private let onSaved: (UUID) -> Void

    init(route: MovementFormRoute, context: NSManagedObjectContext, onSaved: @escaping (UUID) -> Void = { _ in }) {
        let viewModel = MovementFormViewModel(route: route, context: context)
        _viewModel = State(initialValue: viewModel)
        _description = State(initialValue: viewModel.draft.description)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                Picker("Tipo de movimiento", selection: kindSelection) {
                    ForEach(MovementKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                fieldRow(.amount) {
                    LabeledContent("Valor") {
                        CurrencyField("Valor", amount: amount)
                            .foregroundStyle(viewModel.draft.kind.formAmountStyle)
                    }
                }

                fieldRow(.description) {
                    LabeledContent("Descripción") {
                        TextField("Compra de café", text: $description)
                    }
                }

                DatePicker("Fecha", selection: date, in: ...Date.now, displayedComponents: .date)

                fieldRow(.originAccount) {
                    accountPicker(viewModel.originFieldTitle, selection: origin, options: viewModel.originOptions)
                }

                if viewModel.showsDestination {
                    fieldRow(.destinationAccount) {
                        accountPicker("Cuenta destino", selection: destination, options: viewModel.destinationOptions)
                    }
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Regresar", systemImage: "chevron.backward", action: goBack)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.primaryButtonTitle, action: save)
                    .disabled(!viewModel.canSave)
            }
        }
        .confirmationDialog(
            "¿Descartar los cambios?",
            isPresented: $discardConfirmationIsPresented,
            titleVisibility: .visible
        ) {
            Button("Descartar cambios", role: .destructive) { dismiss() }
            Button("Seguir editando", role: .cancel) {}
        }
        .alert(viewModel.saveErrorMessage, isPresented: $viewModel.saveErrorIsPresented) {
            Button("Aceptar", role: .cancel) {}
        }
        .onChange(of: description) { _, newDescription in
            viewModel.updateDescription(newDescription)
            if description != viewModel.draft.description {
                description = viewModel.draft.description
            }
        }
    }

    private var kindSelection: Binding<MovementKind> {
        Binding(get: { viewModel.draft.kind }, set: { viewModel.select(kind: $0) })
    }

    private var amount: Binding<Decimal> {
        Binding(get: { viewModel.draft.amount }, set: { viewModel.updateAmount($0) })
    }

    private var date: Binding<Date> {
        Binding(get: { viewModel.draft.date }, set: { viewModel.updateDate($0) })
    }

    private var origin: Binding<UUID?> {
        Binding(get: { viewModel.draft.originAccountID }, set: { viewModel.selectOrigin($0) })
    }

    private var destination: Binding<UUID?> {
        Binding(get: { viewModel.draft.destinationAccountID }, set: { viewModel.selectDestination($0) })
    }

    @ViewBuilder
    private func accountPicker(_ title: String, selection: Binding<UUID?>, options: [AccountSnapshot]) -> some View {
        if options.isEmpty {
            LabeledContent(title, value: MovementFormViewModel.noAccountsMessage)
        } else {
            Picker(title, selection: selection) {
                ForEach(options) { account in
                    Text(account.name).tag(Optional(account.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func fieldRow(_ field: MovementField, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
            if let error = viewModel.visibleError(for: field) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func goBack() {
        if viewModel.hasChanges {
            discardConfirmationIsPresented = true
        } else {
            dismiss()
        }
    }

    private func save() {
        if let originAccountID = viewModel.save() {
            onSaved(originAccountID)
            dismiss()
        }
    }
}

private extension MovementKind {
    /// Red for expenses, green for incomes and neutral for transfers.
    var formAmountStyle: Color {
        switch self {
        case .expense: .red
        case .income: .green
        case .transfer: .primary
        }
    }
}

#Preview("Crear") {
    NavigationStack {
        MovementFormView(route: .create, context: PersistenceController.preview.container.viewContext)
    }
}

#Preview("Editar") {
    let context = PersistenceController.preview.container.viewContext
    let movement = try? context.fetch(Movement.fetchRequest()).first { $0.kind == .transfer }

    NavigationStack {
        if let movement {
            MovementFormView(route: .edit(movement), context: context)
        }
    }
}

#Preview("Sin cuentas") {
    NavigationStack {
        MovementFormView(route: .create, context: PersistenceController(inMemory: true).container.viewContext)
    }
}
