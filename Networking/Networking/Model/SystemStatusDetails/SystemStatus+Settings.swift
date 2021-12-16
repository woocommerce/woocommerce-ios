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
        public let taxonomies: Taxonomies
        public let productVisibilityTerms: ProductVisibilityTerms
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

    /// Details about a store's product visibility terms.
    ///
    struct ProductVisibilityTerms: Decodable {
        public let excludeFromCatalog, excludeFromSearch, featured, outofstock: String
        public let rated1, rated2, rated3, rated4: String
        public let rated5: String

        enum CodingKeys: String, CodingKey {
            case excludeFromCatalog = "exclude-from-catalog"
            case excludeFromSearch = "exclude-from-search"
            case featured, outofstock
            case rated1 = "rated-1"
            case rated2 = "rated-2"
            case rated3 = "rated-3"
            case rated4 = "rated-4"
            case rated5 = "rated-5"
        }
    }

    /// Details about a store's taxonomies.
    ///
    struct Taxonomies: Codable {
        public let external, grouped, simple, subscription: String
        public let variable, variableSubscription: String

        enum CodingKeys: String, CodingKey {
            case external, grouped, simple, subscription, variable
            case variableSubscription = "variable-subscription"
        }
    }

}
