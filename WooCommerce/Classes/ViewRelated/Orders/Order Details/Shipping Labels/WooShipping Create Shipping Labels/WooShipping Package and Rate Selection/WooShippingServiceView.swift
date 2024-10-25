import SwiftUI

/// View to display the available shipping services (carriers and rates) with the Woo Shipping extension.
struct WooShippingServiceView: View {
    @ObservedObject var viewModel: WooShippingServiceViewModel

    private var carriers: [TopTabItem<WooShippingServiceCardListView>] {
        viewModel.serviceTabs.map { tab in
            TopTabItem(name: tab.id.name,
                       icon: tab.id.logo) {
                WooShippingServiceCardListView(cards: tab.cards)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.shippingService)
                    .headlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            TopTabView(tabs: carriers,
                       tabsContainerHorizontalPadding: 16,
                       unselectedStateColor: .secondary,
                       tabsNameFont: .subheadline.bold(),
                       tabItemContentHorizontalPadding: 6,
                       tabItemContentVerticalPadding: 12)
        }
    }
}

/// View to display a provided list of shipping rate cards with the Woo Shipping extension.
private struct WooShippingServiceCardListView: View {
    var cards: [WooShippingServiceCardViewModel]

    var body: some View {
        VStack {
            ForEach(cards) { card in
                WooShippingServiceCardView(viewModel: card)
                    .fixedSize(horizontal: false, vertical: true) // Prevents card text from being truncated
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

private extension WooShippingServiceView {
    enum Localization {
        static let shippingService = NSLocalizedString("wooShipping.createLabels.rates.shippingService",
                                                       value: "Shipping service",
                                                       comment: "Heading for the shipping service section in the shipping label creation screen.")
    }
}

#Preview {
    WooShippingServiceView(viewModel: .init())
}
