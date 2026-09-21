import Foundation
import Yosemite

/// Destinations the Analytics Hub deep link route can dispatch.
///
/// `focusedCard` opens the hub showing a single card at the requested time range — the
/// shape produced by Store Stats widget metric cells. `defaultHub` opens the hub at its
/// default state and is used when the deep link arrives without resolvable parameters.
///
enum AnalyticsHubDestination: DeepLinkDestinationProtocol {
    case focusedCard(card: AnalyticsCard.CardType,
                     range: AnalyticsHubTimeRangeSelection.SelectionType)
    case defaultHub
}
