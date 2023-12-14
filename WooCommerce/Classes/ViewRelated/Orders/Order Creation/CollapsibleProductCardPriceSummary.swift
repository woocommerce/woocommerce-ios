import SwiftUI

struct CollapsibleProductCardPriceSummary: View {

    private let viewModel: CollapsibleProductCardPriceSummaryViewModel

    init(viewModel: CollapsibleProductCardPriceSummaryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            HStack {
                Text(viewModel.priceQuantityLine)
                    .foregroundColor(.secondary)
                Spacer()
            }
            if let subtotal = viewModel.subtotalLabel {
                Text(subtotal)
                    .if(!viewModel.pricedIndividually) {
                        $0.foregroundColor(.secondary)
                    }
            }
        }
    }
}

struct CollapsibleProductCardPriceSummary_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true, quantity: 2, priceBeforeDiscount: "5", subtotal: "10")
        let bundleViewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false, quantity: 2, priceBeforeDiscount: "0", subtotal: "0")
        CollapsibleProductCardPriceSummary(viewModel: viewModel)
            .previewDisplayName("Priced individually")
        CollapsibleProductCardPriceSummary(viewModel: bundleViewModel)
            .previewDisplayName("Bundled price")
    }
}
