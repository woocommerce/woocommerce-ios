import SwiftUI
import WooFoundation
import struct Yosemite.POSCustomAmount

/// Host for the custom amount flow, pushed over both panes for add and edit.
struct POSCustomAmountFlowView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posCurrencyProvider) private var currencyProvider

    let flow: POSCustomAmountFlow

    var body: some View {
        POSCustomAmountFlowStepsView(
            flow: flow,
            currencySettings: currencyProvider.currencySettings,
            onSubmit: { customAmount in
                posModel.upsertCustomAmount(customAmount, mode: flow.analyticsMode)
                dismiss()
            },
            onDismiss: dismiss
        )
    }

    private func dismiss() {
        posModel.customAmountFlow = nil
    }
}

/// Holds the draft shared by every step, so it needs the currency settings at init.
private struct POSCustomAmountFlowStepsView: View {
    private enum Step: Hashable {
        case form
    }

    let flow: POSCustomAmountFlow
    let currencySettings: CurrencySettings
    let onSubmit: (POSCustomAmount) -> Void
    let onDismiss: () -> Void

    @State private var viewModel: AddCustomAmountFormViewModel
    @State private var path: [Step] = []

    init(flow: POSCustomAmountFlow,
         currencySettings: CurrencySettings,
         onSubmit: @escaping (POSCustomAmount) -> Void,
         onDismiss: @escaping () -> Void) {
        self.flow = flow
        self.currencySettings = currencySettings
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
        self._viewModel = State(wrappedValue: AddCustomAmountFormViewModel(
            currencySettings: currencySettings,
            editing: flow.editingCustomAmount
        ))
    }

    var body: some View {
        // The dashboard ignores the keyboard safe area, so without a navigation host of its own
        // the pinned buttons stay under the keyboard.
        NavigationStack(path: $path) {
            rootStep
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .form:
                        form
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
    }

    @ViewBuilder
    private var rootStep: some View {
        switch flow {
        case .add:
            POSCustomAmountAmountView(
                viewModel: viewModel,
                currencySettings: currencySettings,
                onBack: onDismiss,
                onContinue: { path.append(.form) }
            )
        case .edit:
            form
        }
    }

    private var form: some View {
        AddCustomAmountView(
            viewModel: viewModel,
            onBack: {
                if path.isEmpty {
                    onDismiss()
                } else {
                    path.removeLast()
                }
            },
            onSubmit: onSubmit
        )
    }
}
