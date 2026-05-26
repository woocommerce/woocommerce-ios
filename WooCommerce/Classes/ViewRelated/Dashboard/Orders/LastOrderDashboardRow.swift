import SwiftUI
import Yosemite
import WooFoundation
import NetworkingCore
import Experiments

struct LastOrderDashboardRow: View {
    let data: RowData
    let showDivider: Bool
    let paddedRow: Bool
    let tapHandler: (() -> Void)

    init(data: RowData,
         showDivider: Bool = true,
         paddedRow: Bool = false,
         tapHandler: @escaping () -> Void) {
        self.data = data
        self.showDivider = showDivider
        self.paddedRow = paddedRow
        self.tapHandler = tapHandler
    }

    var body: some View {
        Button {
            tapHandler()
        } label: {
            VStack(spacing: paddedRow ? 0 : nil) {
                HStack {
                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        HStack(spacing: Layout.spacing) {
                            Text(data.number)
                                .subheadlineStyle()

                            Text(data.date)
                                .subheadlineStyle()
                        }
                        Text(data.customerName)
                            .bodyStyle()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Layout.spacing) {
                        HStack(spacing: Layout.badgeSpacing) {
                            Text(data.statusDescription)
                                .foregroundStyle(.black)
                                .footnoteStyle()
                                .padding(.horizontal, Layout.Status.hPadding)
                                .padding(.vertical, Layout.Status.vPadding)
                                .background(data.statusBackgroundColor)
                                .cornerRadius(Layout.Status.cornerRadius)
                            if let fulfillmentText = data.fulfillmentBadgeText {
                                Text(fulfillmentText)
                                    .foregroundStyle(.black)
                                    .footnoteStyle()
                                    .padding(.horizontal, Layout.Status.hPadding)
                                    .padding(.vertical, Layout.Status.vPadding)
                                    .background(data.fulfillmentBadgeBackgroundColor ?? .clear)
                                    .cornerRadius(Layout.Status.cornerRadius)
                            }
                            if let salesChannelText = data.salesChannelText {
                                Text(salesChannelText)
                                    .foregroundStyle(Color(uiColor: Layout.salesChannelLabelTextColor))
                                    .footnoteStyle()
                                    .padding(.horizontal, Layout.Status.hPadding)
                                    .padding(.vertical, Layout.Status.vPadding)
                                    .background(Color(uiColor: Layout.salesChannelLabelBackgroundColor))
                                    .cornerRadius(Layout.Status.cornerRadius)
                            }
                        }

                        Text(data.total)
                            .bodyStyle()
                    }
                }
                .padding(.horizontal, Layout.padding)
                .padding(.vertical, paddedRow ? Layout.chatRowVerticalPadding : 0)
                // Make the whole row width the tap target, not just the rendered text.
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())

                if showDivider {
                    Divider()
                        .padding(.leading, Layout.padding)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

extension LastOrderDashboardRow {
    struct RowData: Equatable {
        let number: String
        let date: String
        let customerName: String
        let total: String
        let statusDescription: String
        let statusBackgroundColor: Color
        let fulfillmentBadgeText: String?
        let fulfillmentBadgeBackgroundColor: Color?
        let salesChannelText: String?
    }
}

// MARK: Constants
//
private extension LastOrderDashboardRow {
    enum Layout {
        static let padding: CGFloat = 16
        static let chatRowVerticalPadding: CGFloat = 12
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

    var rowData: LastOrderDashboardRow.RowData {
        LastOrderDashboardRow.RowData(
            number: number,
            date: date,
            customerName: customerName,
            total: total,
            statusDescription: statusDescription,
            statusBackgroundColor: statusBackgroundColor,
            fulfillmentBadgeText: isFulfillmentStatusRequired ? fulfillmentBadgeText : nil,
            fulfillmentBadgeBackgroundColor: isFulfillmentStatusRequired ? fulfillmentBadgeBackgroundColor : nil,
            salesChannelText: shouldShowSalesChannel ? salesChannelText : nil
        )
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

    private var shouldShowSalesChannel: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleOrdersi1) && isPOSOrder
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
