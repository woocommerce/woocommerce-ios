import SwiftUI

struct CollapsibleProductCardPriceSummary: View {

    private let viewModel: CollapsibleProductCardPriceSummaryViewModel
    private let isLoading: Bool

    init(viewModel: CollapsibleProductCardPriceSummaryViewModel, isLoading: Bool = false) {
        self.viewModel = viewModel
        self.isLoading = isLoading
    }

    var body: some View {
        HStack {
            HStack {
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.subscriptionsInOrderCreationUI) &&
                    viewModel.isSubscriptionProduct {
                    Spacer()
                    Text(viewModel.priceQuantityLine)
                        .foregroundColor(.secondary)
                        .redacted(reason: isLoading ? .placeholder : [])
                        .shimmering(active: isLoading)
                } else {
                    Text(viewModel.priceQuantityLine)
                        .foregroundColor(.secondary)
                        .redacted(reason: isLoading ? .placeholder : [])
                        .shimmering(active: isLoading)
                    Spacer()
                }
            }
            if let price = viewModel.priceBeforeDiscountsLabel {
                Text(price)
                    .if(!viewModel.pricedIndividually) {
                        $0.foregroundColor(.secondary)
                    }
                    .redacted(reason: isLoading ? .placeholder : [])
                    .shimmering(active: isLoading)
            }
        }
    }
}

struct CollapsibleProductCardPriceSummary_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true, isSubscriptionProduct: false, quantity: 2, price: "5")
        let bundleViewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false, isSubscriptionProduct: false, quantity: 2, price: "0")
        CollapsibleProductCardPriceSummary(viewModel: viewModel, isLoading: false)
            .previewDisplayName("Priced individually")
        CollapsibleProductCardPriceSummary(viewModel: bundleViewModel, isLoading: false)
            .previewDisplayName("Bundled price")
    }
}
