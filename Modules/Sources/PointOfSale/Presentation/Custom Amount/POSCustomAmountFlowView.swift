import SwiftUI

/// Host for the custom amount flow, pushed over both panes for add and edit.
struct POSCustomAmountFlowView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posCurrencyProvider) private var currencyProvider

    let flow: POSCustomAmountFlow

    var body: some View {
        // The dashboard ignores the keyboard safe area, so without a navigation host of its own
        // the form's pinned submit button stays under the keyboard.
        NavigationStack {
            AddCustomAmountView(
                currencySettings: currencyProvider.currencySettings,
                editing: flow.editingCustomAmount,
                onDismiss: dismiss,
                onSubmit: { customAmount in
                    posModel.upsertCustomAmount(customAmount, mode: flow.analyticsMode)
                }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func dismiss() {
        posModel.customAmountFlow = nil
    }
}
