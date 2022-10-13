import Foundation

public struct WooCommerceComUTMProvider: UTMParametersProviding {
    public let parameters: [UTMParameterKey: String?]

    public init(campaign: String,
         source: String,
         content: String?) {
        parameters = [
            .medium: Constants.wooCommerceComUtmMedium,
            .campaign: campaign,
            .source: source,
            .content: content
        ]
    }

    private enum Constants {
        static let wooCommerceComUtmMedium = "woo_ios"
    }
}
