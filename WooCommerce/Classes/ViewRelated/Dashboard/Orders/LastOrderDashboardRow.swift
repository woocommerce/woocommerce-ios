import SwiftUI
import Yosemite
import WooFoundation
import NetworkingCore
import Experiments

/// Used in Last Order Dashboard card
///
struct LastOrderDashboardRow: View {
    let viewModel: LastOrderDashboardRowViewModel
    let tapHandler: (() -> Void)

    var body: some View {
        Button {
            tapHandler()
        } label: {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        HStack(spacing: Layout.spacing) {
                            Text(viewModel.number)
                                .subheadlineStyle()

                            Text(viewModel.date)
                                .subheadlineStyle()
                        }
                        Text(viewModel.customerName)
                            .bodyStyle()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Layout.spacing) {
                        HStack(spacing: Layout.badgeSpacing) {
                            Text(viewModel.statusDescription)
                                .foregroundStyle(.black)
                                .footnoteStyle()
                                .padding(.horizontal, Layout.Status.hPadding)
                                .padding(.vertical, Layout.Status.vPadding)
                                .background(viewModel.statusBackgroundColor)
                                .cornerRadius(Layout.Status.cornerRadius)
                                if let fulfillmentText = viewModel.fulfillmentBadgeText,
                                   viewModel.isFulfillmentStatusRequired {
                                    Text(fulfillmentText)
                                        .foregroundStyle(.black)
                                        .footnoteStyle()
                                        .padding(.horizontal, Layout.Status.hPadding)
                                        .padding(.vertical, Layout.Status.vPadding)
                                        .background(viewModel.fulfillmentBadgeBackgroundColor)
                                        .cornerRadius(Layout.Status.cornerRadius)
                                }
                            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleOrdersi1),
                               viewModel.isPOSOrder {
                                Text(viewModel.salesChannelText)
                                    .foregroundStyle(Color(uiColor: Layout.salesChannelLabelTextColor))
                                    .footnoteStyle()
                                    .padding(.horizontal, Layout.Status.hPadding)
                                    .padding(.vertical, Layout.Status.vPadding)
                                    .background(Color(uiColor: Layout.salesChannelLabelBackgroundColor))
                                    .cornerRadius(Layout.Status.cornerRadius)
                            }
                        }

                        Text(viewModel.total)
                            .bodyStyle()
                    }
                }
                .padding(.horizontal, Layout.padding)

                Divider()
                    .padding(.leading, Layout.padding)
            }
        }
    }
}

// MARK: Constants
//
private extension LastOrderDashboardRow {
    enum Layout {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let badgeSpacing: CGFloat = 6
        static let salesChannelLabelBackgroundColor = UIColor.withColorStudio(.wooCommercePurple, shade: .shade10)
        static let salesChannelLabelTextColor = UIColor.withColorStudio(.wooCommercePurple, shade: .shade80)

        enum Status {
            static let hPadding: CGFloat = 8
            static let vPadding: CGFloat = 4
            static let cornerRadius: CGFloat = 4
        }
    }
}

struct LastOrderDashboardRowViewModel {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    let order: Order
    private let isCIAB: Bool

    init(order: Order, isCIAB: Bool = false) {
        self.order = order
        self.isCIAB = isCIAB
    }

    var isPOSOrder: Bool {
        order.salesChannel == .pointOfSale
    }

    var isFulfillmentStatusRequired: Bool {
        /// isCIAB gating is pending a planned refactoring
        isCIAB && order.fulfillmentStatus != .unknown
    }

    var salesChannelText: String {
        order.salesChannel?.description ?? ""
    }

    var number: String {
        "#\(order.number)"
    }

    var customerName: String {
        if let fullName = order.billingAddress?.fullName, fullName.isNotEmpty {
            return fullName
        }
        return Localization.guestName
    }

    var statusDescription: String {
        isCIAB ? CIABOrderStatusMapper.displayName(for: order.status) : order.status.description
    }

    /// The value will only include the year if the `createdDate` is not from the current year.
    ///
    var date: String {
        let isSameYear = order.dateCreated.isSameYear(as: Date())
        let formatter: DateFormatter = isSameYear ? .monthAndDayFormatter : .mediumLengthLocalizedDateFormatter
        formatter.timeZone = .siteTimezone
        return formatter.string(from: order.dateCreated)
    }

    /// The localized unabbreviated total which includes the currency.
    ///
    /// Example: $48,415,504.20
    ///
    var total: String {
        currencyFormatter.formatAmount(order.total, with: order.currency) ?? ""
    }

    var statusBackgroundColor: Color {
        let displayStatus = isCIAB ? CIABOrderStatusMapper.displayStatus(for: order.status) : order.status
        return Color(uiColor: displayStatus.backgroundColor)
    }

    /// Returns the fulfillment badge text for CIAB orders, or `nil` if the badge should not be shown.
    var fulfillmentBadgeText: String? {
        order.fulfillmentStatus.badgeText()
    }

    /// Background color for the fulfillment badge.
    var fulfillmentBadgeBackgroundColor: Color {
        order.fulfillmentStatus.badgeBackgroundSwiftUIColor
    }
}

// MARK: Identifiable Conformance
//
extension LastOrderDashboardRowViewModel: Identifiable {
    var id: Int64 {
        order.orderID
    }
}

private extension LastOrderDashboardRowViewModel {
    enum Localization {
        static let guestName = NSLocalizedString(
            "lastOrderDashboardRowViewModel.guestName",
            value: "Guest",
            comment: "In Last Orders dashboard card list, the name of the billed person when there are no first and last name."
        )
    }
}
