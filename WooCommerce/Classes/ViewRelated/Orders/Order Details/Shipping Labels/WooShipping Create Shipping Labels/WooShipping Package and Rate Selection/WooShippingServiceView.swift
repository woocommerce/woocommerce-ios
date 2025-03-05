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
        if viewModel.hasDestinationAddress {
            VStack(alignment: .leading) {
                HStack {
                    Text(Localization.shippingService)
                        .headlineStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Menu {
                        ForEach(WooShippingServiceViewModel.SortOrder.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortShipping(by: option)
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                    if viewModel.sortOrder == option {
                                        Image(uiImage: .checkmarkStyledImage)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(Localization.sortBy)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .foregroundStyle(Color(.primary))
                    }
                }
                TopTabView(tabs: carriers,
                           tabsContainerHorizontalPadding: 16,
                           unselectedStateColor: .secondary,
                           tabsNameFont: .subheadline.bold(),
                           tabItemContentHorizontalPadding: 6,
                           tabItemContentVerticalPadding: 12)
                .redacted(reason: viewModel.loadingState == .loading ? .placeholder : [])
                .shimmering(active: viewModel.loadingState == .loading)
                .padding(.horizontal, Layout.padding * -1) // Offset the additional padding in TopTabView
            }
            .padding(.vertical, Layout.padding)
        } else {
            VStack(spacing: Layout.placeholderPadding) {
                Image(uiImage: .wooShippingRatesPlaceholder)
                VStack(spacing: Layout.innerSpacing) {
                    Text(Localization.noDestinationAddressTitle)
                        .font(.subheadline)
                        .bold()
                    Text(Localization.noDestinationAddressMessage)
                        .subheadlineStyle()
    var errorState: some View {
        VStack(spacing: Layout.padding) {
            Image(uiImage: .grayErrorIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(Localization.failedLoadingDataError)
                .multilineTextAlignment(.center)
            Button(Localization.retryCTA) {
                if let package = viewModel.selectedPackage {
                    viewModel.loadLabelRates(for: package)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(Layout.placeholderPadding)
            .roundedBorder(cornerRadius: 8, lineColor: Color(.border), lineWidth: 1, dashed: true)
            .padding(.vertical, Layout.padding)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(WooShippingServiceView.Layout.placeholderPadding)
    }

    var progressView: some View {
        VStack(spacing: Layout.placeholderPadding) {
            Image(uiImage: .wooShippingRatesPlaceholder)

            ProgressView()
                .progressViewStyle(.circular)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(Layout.placeholderPadding)
        .roundedBorder(cornerRadius: 8, lineColor: Color(.border), lineWidth: 1, dashed: true)
        .padding(.vertical, Layout.padding)
    }
}

private struct MissingDataStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: WooShippingServiceView.Layout.placeholderPadding) {
            Image(uiImage: .wooShippingRatesPlaceholder)
            VStack(spacing: WooShippingServiceView.Layout.innerSpacing) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(message)
                    .subheadlineStyle()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(WooShippingServiceView.Layout.placeholderPadding)
        .roundedBorder(cornerRadius: 8, lineColor: Color(.border), lineWidth: 1, dashed: true)
        .padding(.vertical, WooShippingServiceView.Layout.padding)
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
        .padding()
    }
}

fileprivate extension WooShippingServiceView {
    enum Layout {
        static let padding: CGFloat = 16
        static let innerSpacing: CGFloat = 8
        static let placeholderPadding: CGFloat = 32
        static let errorIconSize: CGFloat = 86
    }
}

private extension WooShippingServiceView {
    enum Localization {
        static let shippingService = NSLocalizedString("wooShipping.createLabels.rates.shippingService",
                                                       value: "Shipping service",
                                                       comment: "Heading for the shipping service section in the shipping label creation screen.")
        static let sortBy = NSLocalizedString("wooShipping.createLabels.rates.sortBy",
                                              value: "Sort by",
                                              comment: "Label for the menu to select a sort order for shipping rates in the shipping label creation screen.")
        static let noDestinationAddressTitle = NSLocalizedString("wooShipping.createLabels.rates.noDestinationAddressTitle",
                                                                 value: "Add a destination address to get shipping rates",
                                                                 comment: "Title displayed when no destination address is provided " +
                                                                 "in the shipping label creation screen.")
        static let noDestinationAddressMessage = NSLocalizedString("wooShipping.createLabels.rates.noDestinationAddressMessage",
                                                                   value: "We need to know where this package is going " +
                                                                   "before we can show the available shipping rates.",
                                                                   comment: "Message displayed when no destination address is provided " +
                                                                   "in the shipping label creation screen.")
        static let noWeightTitle = NSLocalizedString("wooShipping.createLabels.rates.noWeightTitle",
                                                     value: "Add shipment weight to get shipping rates",
                                                     comment: "Title displayed when no shipment weight is provided " +
                                                     "in the shipping label creation screen.")
        static let noWeightMessage = NSLocalizedString("wooShipping.createLabels.rates.noWeightMessage",
                                                       value: "We need to know the shipment weight " +
                                                       "before we can show the available shipping rates.",
                                                       comment: "Message displayed when no shipment weight is provided " +
                                                       "in the shipping label creation screen.")
        static let failedLoadingDataError = NSLocalizedString("wooShipping.createLabels.rates.failedLoadingDataError",
                                                              value: "We are unable to load shipping rates",
                                                              comment: "Error message when loading shipping label rates "
                                                              + "failed on the shipping label creation screen")
        static let retryCTA = NSLocalizedString("wooShipping.createLabels.retryCTA",
                                                value: "Retry",
                                                comment: "Button to retry loading data on the shipping label creation screen")
    }
}
