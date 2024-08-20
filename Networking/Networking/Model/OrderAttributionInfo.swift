import Foundation
import Codegen

/// Order's attribution info helps to know the source of the order
///
public struct OrderAttributionInfo: Equatable, Sendable, GeneratedFakeable, GeneratedCopiable {
    public let sourceType: String?
    public let campaign: String?
    public let source: String?
    public let medium: String?
    public let deviceType: String?
    public let sessionPageViews: String?

    public init(sourceType: String?,
                campaign: String?,
                source: String?,
                medium: String?,
                deviceType: String?,
                sessionPageViews: String?) {
        self.sourceType = sourceType
        self.campaign = campaign
        self.source = source
        self.medium = medium
        self.deviceType = deviceType
        self.sessionPageViews = sessionPageViews
    }

    public init(metaData: [MetaData]) {
        var sourceType: String?
        var campaign: String?
        var source: String?
        var medium: String?
        var deviceType: String?
        var sessionPageViews: String?
        for item in metaData {
            switch item.key {
            case Keys.sourceType.rawValue:
                sourceType = item.value
            case Keys.campaign.rawValue:
                campaign = item.value
            case Keys.source.rawValue:
                source = item.value
            case Keys.medium.rawValue:
                medium = item.value
            case Keys.deviceType.rawValue:
                deviceType = item.value
            case Keys.sessionPageViews.rawValue:
                sessionPageViews = item.value
            default:
                continue
            }
        }
        self.init(sourceType: sourceType,
                  campaign: campaign,
                  source: source,
                  medium: medium,
                  deviceType: deviceType,
                  sessionPageViews: sessionPageViews)
    }
}

extension OrderAttributionInfo {
    enum Keys: String {
        case sourceType = "_wc_order_attribution_source_type"
        case campaign = "_wc_order_attribution_utm_campaign"
        case source = "_wc_order_attribution_utm_source"
        case medium = "_wc_order_attribution_utm_medium"
        case deviceType = "_wc_order_attribution_device_type"
        case sessionPageViews = "_wc_order_attribution_session_pages"
    }
}

public extension OrderAttributionInfo {
    enum Values {
        /// Sent in create order request to mark the order as created from mobile
        ///
        public static let mobileAppSourceType = "mobile_app"
    }
}
