import Foundation

public extension SystemStatus {
    /// Details about a store's settings in its system status report.
    ///
    struct Settings: Decodable {
        let apiEnabled, forceSSL: Bool
        let currency, currencySymbol, currencyPosition, thousandSeparator: String
        let decimalSeparator: String
        let numberOfDecimals: Int
        let geolocationEnabled: Bool
        let taxonomies: Taxonomies
        let productVisibilityTerms: ProductVisibilityTerms
        let woocommerceCOMConnected: String

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
        let excludeFromCatalog, excludeFromSearch, featured, outofstock: String
        let rated1, rated2, rated3, rated4: String
        let rated5: String

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
        let external, grouped, simple, subscription: String
        let variable, variableSubscription: String

        enum CodingKeys: String, CodingKey {
            case external, grouped, simple, subscription, variable
            case variableSubscription = "variable-subscription"
        }
    }

}
