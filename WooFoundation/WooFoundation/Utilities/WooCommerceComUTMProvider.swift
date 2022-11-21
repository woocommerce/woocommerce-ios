import Foundation

public struct WooCommerceComUTMProvider: UTMParametersProviding {
    public var limitToHosts: [String]? = ["woocommerce.com"]

    public let parameters: [UTMParameterKey: String?]

    public init(campaign: String,
                source: String,
                content: String?,
                siteID: Int64?) {
        let siteIDString: String?
        if let siteID = siteID {
            siteIDString = String(siteID)
        } else {
            siteIDString = nil
        }
        parameters = [
            .medium: Constants.wooCommerceComUtmMedium,
            .campaign: campaign,
            .source: source,
            .content: content,
            .term: siteIDString
        ]
    }

    private enum Constants {
        static let wooCommerceComUtmMedium = "woo_ios"
    }
}
