import SwiftUI
import Yosemite
import WooFoundation

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
                        Text(viewModel.statusDescription)
                            .foregroundStyle(.black)
                            .captionStyle()
                            .padding(.horizontal, Layout.Status.hPadding)
                            .padding(.vertical, Layout.Status.vPadding)
                            .background(viewModel.statusBackgroundColor)
                            .cornerRadius(Layout.Status.cornerRadius)

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

        enum Status {
            static let hPadding: CGFloat = 8
            static let vPadding: CGFloat = 2
            static let cornerRadius: CGFloat = 2
        }
    }
}

struct LastOrderDashboardRowViewModel {
    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    let order: Order

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
        order.status.description
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
        Color(uiColor: order.status.backgroundColor)
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
