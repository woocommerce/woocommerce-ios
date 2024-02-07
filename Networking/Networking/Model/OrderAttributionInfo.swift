import Foundation
import Codegen

/// Order's attribution info helps to know the source of the order
///
public struct OrderAttributionInfo: Equatable, GeneratedFakeable, GeneratedCopiable {

    // Source types based on
    // swiftlint:disable:next line_length
    // https://github.com/woocommerce/woocommerce/blob/4dcc7d8bf80dcd660e0e999ca84794ef61627d41/plugins/woocommerce/src/Internal/Traits/OrderAttributionMeta.php#L276-L314
    //
    public enum SourceType: Equatable {
        case utm
        case organic
        case referral
        case typein
        case admin
        case unknown(_ sourceType: String)

        init(string: String) {
            switch string {
            case "utm":
                self = .utm
            case "organic":
                self = .organic
            case "referral":
                self = .referral
            case "typein":
                self = .typein
            case "admin":
                self = .admin
            default:
                self = .unknown(string)
            }
        }
    }

    public let sourceType: SourceType?
    public let campaign: String?
    public let source: String?
    public let medium: String?
    public let deviceType: String?
    public let sessionPageViews: String?

    public init(sourceType: SourceType?,
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

    public init(metaData: [OrderMetaData]) {
        var sourceType: SourceType?
        var campaign: String?
        var source: String?
        var medium: String?
        var deviceType: String?
        var sessionPageViews: String?
        for item in metaData {
            switch item.key {
            case Keys.sourceType.rawValue:
                sourceType = SourceType(string: item.value)
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

private extension OrderAttributionInfo {
    enum Keys: String {
        case sourceType = "_wc_order_attribution_source_type"
        case campaign = "_wc_order_attribution_utm_campaign"
        case source = "_wc_order_attribution_utm_source"
        case medium = "_wc_order_attribution_utm_medium"
        case deviceType = "_wc_order_attribution_device_type"
        case sessionPageViews = "_wc_order_attribution_session_pages"
    }
}
