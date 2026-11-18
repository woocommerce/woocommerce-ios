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
    private enum Step {
        case initialAmount
        case details
        case editAmount
        case name
    }

    let currencySettings: CurrencySettings
    let onSubmit: (POSCustomAmount) -> Void
    let onDismiss: () -> Void

    @State private var viewModel: AddCustomAmountFormViewModel
    @State private var step: Step

    init(flow: POSCustomAmountFlow,
         currencySettings: CurrencySettings,
         onSubmit: @escaping (POSCustomAmount) -> Void,
         onDismiss: @escaping () -> Void) {
        self.currencySettings = currencySettings
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
        self._viewModel = State(wrappedValue: AddCustomAmountFormViewModel(
            currencySettings: currencySettings,
            editing: flow.editingCustomAmount
        ))
        self._step = State(initialValue: flow.editingCustomAmount == nil ? .initialAmount : .details)
    }

    var body: some View {
        // The dashboard ignores the keyboard safe area, so the flow needs its own navigation host.
        // Steps replace the root so Back from Details cannot pop to the initial Amount screen.
        NavigationStack {
            Group {
                switch step {
                case .initialAmount:
                    amountView(mode: .initial, onBack: onDismiss)
                case .details:
                    AddCustomAmountView(viewModel: viewModel,
                                        onBack: onDismiss,
                                        onEditAmount: { step = .editAmount },
                                        onEditName: { step = .name },
                                        onSubmit: onSubmit)
                case .editAmount:
                    amountView(mode: .edit, onBack: { step = .details })
                case .name:
                    POSCustomAmountNameView(name: viewModel.name,
                                            onBack: { step = .details },
                                            onSave: { name in
                        viewModel.name = name
                        step = .details
                    })
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func amountView(mode: POSCustomAmountAmountView.Mode, onBack: @escaping () -> Void) -> some View {
        POSCustomAmountAmountView(viewModel: viewModel,
                                  currencySettings: currencySettings,
                                  mode: mode,
                                  onBack: onBack,
                                  onSave: { amount in
            viewModel.setAmount(amount)
            step = .details
        })
    }
}
