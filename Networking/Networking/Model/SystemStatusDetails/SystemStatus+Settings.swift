import Foundation

public extension SystemStatus {
    /// Details about a store's settings in its system status report.
    ///
    struct Settings: Decodable {
        public let apiEnabled, forceSSL: Bool
        public let currency, currencySymbol, currencyPosition, thousandSeparator: String
        public let decimalSeparator: String
        public let numberOfDecimals: Int
        public let geolocationEnabled: Bool
        public let taxonomies: [String: String]
        public let productVisibilityTerms: [String: String]
        public let woocommerceCOMConnected: String

        enum CodingKeys: String, CodingKey {
            case apiEnabled = "api_enabled"
            case forceSSL = "force_ssl"
            case currency
            case currencySymbol = "currency_symbol"
            case currencyPosition = "currency_position"
            case thousandSeparator = "thousand_separator"
            case decimalSeparator = "decimal_separator"
            case numberOfDecimals = "number_of_decimals"
            case geolocationEnabled = "geolocation_enabled"
            case taxonomies
            case productVisibilityTerms = "product_visibility_terms"
            case woocommerceCOMConnected = "woocommerce_com_connected"
        }
    }
}
