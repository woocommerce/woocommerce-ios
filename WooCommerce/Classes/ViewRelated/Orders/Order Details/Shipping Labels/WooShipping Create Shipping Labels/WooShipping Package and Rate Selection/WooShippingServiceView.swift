import Foundation
import SwiftUI

/// View to display the available shipping services (carriers and rates) with the Woo Shipping extension.
struct WooShippingServiceView: View {
    @ObservedObject var viewModel: WooShippingServiceViewModel

    private var carriers: [TopTabItem<EmptyView>] {
        viewModel.serviceTabs.map { tab in
            TopTabItem(name: tab.id.name,
                       icon: tab.id.logo) {
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            headerView

            switch viewModel.loadingState {
            case .empty:
                EmptyView()
            case .loading:
                progressView
            case .loaded:
                contentView
            case .error(let error):
                switch error {
                case WooShippingServiceViewModel.Error.missingDestinationAddress:
                    MissingDataStateView(title: Localization.noDestinationAddressTitle,
                                         message: Localization.noDestinationAddressMessage)
                case WooShippingServiceViewModel.Error.missingShipmentWeight:
                    MissingDataStateView(title: Localization.noWeightTitle,
                                         message: Localization.noWeightMessage)
                case WooShippingServiceViewModel.Error.failedLoadingLabelRates:
                    ErrorState(message: Localization.failedLoadingDataError) {
                        if let package = viewModel.selectedPackage {
                            viewModel.loadLabelRates(for: package)
                        }
                    }
                case .noRatesAvailable(let isHAZMAT):
                    ErrorState(message: isHAZMAT ?
                               Localization.noRatesAvailableWithHAZMAT :
                               Localization.noRatesAvailableNoHAZMAT)
                }
            }
        }
        .padding(.vertical, Layout.padding)
    }

    var headerView: some View {
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
    }

    var contentView: some View {
        VStack(spacing: 0) {
            TopTabView(tabs: carriers,
                       showContent: false,
                       selectedTabIndex: $viewModel.selectedTabIndex,
                       tabsContainerHorizontalPadding: 16,
                       unselectedStateColor: .secondary,
                       tabsNameFont: .subheadline.bold(),
                       tabItemContentHorizontalPadding: 6,
                       tabItemContentVerticalPadding: 12)
            WooShippingServiceCardListView(cards: viewModel.displayedServiceCards)
        }
        .padding(.horizontal, Layout.padding * -1) // Offset the additional padding in TopTabView
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

private struct ErrorState: View {
    let message: String
    let retryAction: (() -> Void)?

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: WooShippingServiceView.Layout.padding) {
            Image(uiImage: .grayErrorIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(message)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button(WooShippingServiceView.Localization.retryCTA) {
                    retryAction()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(WooShippingServiceView.Layout.placeholderPadding)
    }

    enum Layout {
        static let errorIconSize: CGFloat = 86
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
        static let noRatesAvailableNoHAZMAT = NSLocalizedString(
            "wooShipping.createLabels.rates.noRatesAvailableNoHAZMAT",
            value: "We couldn't find a shipping service for the combination of the selected package "
            + "and the total shipment weight. Please adjust your input and try again.",
            comment: "Error message when no shipping rates were found "
            + "based on the combination of the selected package and the total shipment weight."
        )
        static let noRatesAvailableWithHAZMAT = NSLocalizedString(
            "wooShipping.createLabels.rates.noRatesAvailableWithHAZMAT",
            value: "We couldn't find a shipping service for the combination of the selected HAZMAT category, "
            + "the selected package, and the total shipment weight. Please adjust your input and try again.",
            comment: "Error message when no shipping rates were found "
            + "based on the combination of the selected HAZMAT category, package and the total shipment weight."
        )
        static let retryCTA = NSLocalizedString("wooShipping.createLabels.rates.retryCTA",
                                                value: "Retry",
                                                comment: "Button to retry loading data on the shipping label creation screen")
    }
}
