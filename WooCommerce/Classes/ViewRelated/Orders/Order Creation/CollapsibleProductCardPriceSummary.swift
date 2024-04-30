import SwiftUI

struct CollapsibleProductCardPriceSummary: View {

    private let viewModel: CollapsibleProductCardPriceSummaryViewModel

    init(viewModel: CollapsibleProductCardPriceSummaryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            HStack {
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationUI) &&
                    viewModel.isSubscriptionProduct {
                    Spacer()
                    Text(viewModel.priceQuantityLine)
                        .foregroundColor(.secondary)
                } else {
                    Text(viewModel.priceQuantityLine)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            if let price = viewModel.priceBeforeDiscountsLabel {
                Text(price)
                    .if(!viewModel.pricedIndividually) {
                        $0.foregroundColor(.secondary)
                    }
            }
        }
    }
}

struct CollapsibleProductCardPriceSummary_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true, isSubscriptionProduct: false, quantity: 2, price: "5")
        let bundleViewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false, isSubscriptionProduct: false, quantity: 2, price: "0")
        CollapsibleProductCardPriceSummary(viewModel: viewModel)
            .previewDisplayName("Priced individually")
        CollapsibleProductCardPriceSummary(viewModel: bundleViewModel)
            .previewDisplayName("Bundled price")
    }
}
