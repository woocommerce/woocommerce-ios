import Foundation
import Yosemite
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsReportCardViewModel(title: "REVENUE",
                                                              leadingTitle: "Total Sales",
                                                              leadingValue: "$3.234",
                                                              leadingDelta: "+23%",
                                                              leadingDeltaColor: .withColorStudio(.green, shade: .shade50),
                                                              trailingTitle: "Net Sales",
                                                              trailingValue: "$2.324",
                                                              trailingDelta: "-4%",
                                                              trailingDeltaColor: .withColorStudio(.red, shade: .shade40))

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                                             leadingTitle: Localization.OrderCard.leadingTitle,
                                                             leadingValue: Constants.placeholderLabel,
                                                             leadingDelta: Constants.placeholderLabel,
                                                             leadingDeltaColor: Constants.deltaColor(for: .negative),
                                                             trailingTitle: Localization.OrderCard.trailingTitle,
                                                             trailingValue: Constants.placeholderLabel,
                                                             trailingDelta: Constants.placeholderLabel,
                                                             trailingDeltaColor: Constants.deltaColor(for: .negative))

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
        static let placeholderLabel = "-"
        static func deltaColor(for direction: StatsDataTextFormatter.DeltaPercentage.Direction) -> UIColor {
            switch direction {
            case .positive:
                return .withColorStudio(.green, shade: .shade50)
            case .negative, .zero:
                return .withColorStudio(.red, shade: .shade40)
            }
        }
    }

    enum Localization {
        enum OrderCard {
            static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
        }
    }
}
