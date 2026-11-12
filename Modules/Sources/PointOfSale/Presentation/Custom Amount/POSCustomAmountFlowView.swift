import SwiftUI

/// Host for the custom amount flow, pushed over both panes for add and edit.
struct POSCustomAmountFlowView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posCurrencyProvider) private var currencyProvider

    let flow: POSCustomAmountFlow

    var body: some View {
        AddCustomAmountView(
            currencySettings: currencyProvider.currencySettings,
            editing: flow.editingCustomAmount,
            onDismiss: dismiss,
            onSubmit: { customAmount in
                posModel.upsertCustomAmount(customAmount, mode: flow.analyticsMode)
            }
        )
    }

    private func dismiss() {
        posModel.customAmountFlow = nil
    }
}
