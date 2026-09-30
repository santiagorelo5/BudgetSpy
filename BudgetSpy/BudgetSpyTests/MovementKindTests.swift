//
//  MovementKindTests.swift
//  BudgetSpyTests
//

import Testing
@testable import BudgetSpy

@MainActor
struct MovementKindTests {
    @Test(arguments: [
        (MovementKind.expense, "Gasto", "arrow.up.right.circle.fill"),
        (MovementKind.income, "Ingreso", "arrow.down.left.circle.fill"),
        (MovementKind.transfer, "Transferencia", "arrow.left.arrow.right.circle.fill"),
    ])
    func nameAndIcon(kind: MovementKind, name: String, systemImage: String) {
        #expect(kind.displayName == name)
        #expect(kind.rawValue == name)
        #expect(kind.systemImage == systemImage)
    }

    @Test func casesAreInFormOrder() {
        #expect(MovementKind.allCases == [.expense, .income, .transfer])
    }
}
