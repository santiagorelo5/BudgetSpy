//
//  AccountFormView.swift
//  BudgetSpy
//

import CoreData
import SwiftUI

struct AccountFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AccountFormViewModel
    // Typed text is kept here so the field is rewritten when the view model truncates it.
    @State private var name: String
    @State private var lastFourDigits: String
    @State private var discardConfirmationIsPresented = false

    init(route: AccountFormRoute, context: NSManagedObjectContext) {
        let viewModel = AccountFormViewModel(route: route, context: context)
        _viewModel = State(initialValue: viewModel)
        _name = State(initialValue: viewModel.draft.name)
        _lastFourDigits = State(initialValue: viewModel.draft.lastFourDigits)
    }

    var body: some View {
        Form {
            Section {
                AccountCardView(content: viewModel.cardContent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Picker("Tipo de cuenta", selection: kindSelection) {
                    ForEach(AccountKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.isKindLocked)
            }

            Section {
                fieldRow(.name) {
                    LabeledContent("Nombre") {
                        TextField(AccountCardContent.namePlaceholder, text: $name)
                            .textInputAutocapitalization(.words)
                    }
                }

                fieldRow(.lastFourDigits) {
                    LabeledContent("Últimos 4 dígitos") {
                        TextField("1234", text: $lastFourDigits)
                            .keyboardType(.numberPad)
                            .monospacedDigit()
                    }
                }

                fieldRow(.balance) {
                    LabeledContent(viewModel.draft.kind.balanceTitle) {
                        CurrencyField(viewModel.draft.kind.balanceTitle, amount: balance)
                    }
                }

                if viewModel.draft.kind.requiresCreditLimit {
                    fieldRow(.creditLimit) {
                        LabeledContent("Límite") {
                            CurrencyField("Límite", amount: creditLimit)
                        }
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
        .alert("No se pudo guardar la cuenta. Intenta de nuevo.", isPresented: $viewModel.saveErrorIsPresented) {
            Button("Aceptar", role: .cancel) {}
        }
        .onChange(of: name) { _, newName in
            viewModel.updateName(newName)
            if name != viewModel.draft.name {
                name = viewModel.draft.name
            }
        }
        .onChange(of: lastFourDigits) { _, newDigits in
            viewModel.updateLastFourDigits(newDigits)
            if lastFourDigits != viewModel.draft.lastFourDigits {
                lastFourDigits = viewModel.draft.lastFourDigits
            }
        }
    }

    private var kindSelection: Binding<AccountKind> {
        Binding(get: { viewModel.draft.kind }, set: { viewModel.select(kind: $0) })
    }

    private var balance: Binding<Decimal> {
        Binding(get: { viewModel.draft.balance }, set: { viewModel.updateBalance($0) })
    }

    private var creditLimit: Binding<Decimal> {
        Binding(get: { viewModel.draft.creditLimit }, set: { viewModel.updateCreditLimit($0) })
    }

    private func fieldRow(_ field: AccountField, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
            if let error = viewModel.visibleError(for: field) {
                Text(error.message)
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
        if viewModel.save() {
            dismiss()
        }
    }
}

#Preview("Crear") {
    NavigationStack {
        AccountFormView(route: .create, context: PersistenceController.preview.container.viewContext)
    }
}

#Preview("Editar") {
    let context = PersistenceController.preview.container.viewContext
    let request: NSFetchRequest<Account> = Account.fetchRequest()
    let account = try? context.fetch(request).first

    NavigationStack {
        if let account {
            AccountFormView(route: .edit(account), context: context)
        }
    }
}
