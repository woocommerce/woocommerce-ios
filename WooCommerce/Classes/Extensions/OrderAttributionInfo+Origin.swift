import Foundation
import struct Yosemite.OrderAttributionInfo

/// Provides `Origin` value for order attribution
///
/// Implementation based on https://github.com/woocommerce/woocommerce/blob/trunk/plugins/woocommerce/src/Internal/Traits/OrderAttributionMeta.php#L276-L314
///
extension OrderAttributionInfo {
    var origin: String {
        switch sourceType {
        case "utm":
            return String.localizedStringWithFormat(Localization.source, source ?? Localization.unknown)
        case "organic":
            return String.localizedStringWithFormat(Localization.organic, source ?? Localization.unknown)
        case "referral":
            return String.localizedStringWithFormat(Localization.referral, source ?? Localization.unknown)
        case "typein":
            return Localization.direct
        case "admin":
            return Localization.webAdmin
        case OrderAttributionInfo.Values.mobileAppSourceType:
            return Localization.mobileApp
        default:
            return Localization.unknown
        }
    }
}

extension OrderAttributionInfo {
    enum Localization {
        static let source = NSLocalizedString(
            "orderAttributionInfo.source",
            value: "Source: %1$@",
            comment: "Origin in Order Attribution Section on Order Details screen." +
            "The placeholder is the source." +
            "Reads like: Source: woocommerce.com"
        )

        static let organic = NSLocalizedString(
            "orderAttributionInfo.organic",
            value: "Organic: %1$@",
            comment: "Origin in Order Attribution Section on Order Details screen." +
            "The placeholder is the source." +
            "Reads like: Organic: woocommerce.com"
        )

        static let referral = NSLocalizedString(
            "orderAttributionInfo.referral",
            value: "Referral: %1$@",
            comment: "Origin in Order Attribution Section on Order Details screen." +
            "The placeholder is the source." +
            "Reads like: Referral: woocommerce.com"
        )

        static let direct = NSLocalizedString(
            "orderAttributionInfo.direct",
            value: "Direct",
            comment: "Origin in Order Attribution Section on Order Details screen."
        )

        static let webAdmin = NSLocalizedString(
            "orderAttributionInfo.webAdmin",
            value: "Web admin",
            comment: "Origin in Order Attribution Section on Order Details screen."
        )

        static let mobileApp = NSLocalizedString(
            "orderAttributionInfo.mobileApp",
            value: "Mobile App",
            comment: "Origin in Order Attribution Section on Order Details screen."
        )

        static let unknown = NSLocalizedString(
            "orderAttributionInfo.unknown",
            value: "Unknown",
            comment: "Origin in Order Attribution Section on Order Details screen."
        )
    }
}
