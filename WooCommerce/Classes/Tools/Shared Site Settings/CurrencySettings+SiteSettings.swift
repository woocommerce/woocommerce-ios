import Networking
import WooFoundationCore

extension CurrencySettings {
    /// Convenience initializer for currency settings returned from WooCommerce general site settings.
    convenience init(siteSettings: [SiteSetting]) {
        self.init()

        siteSettings.forEach { updateCurrencyOptions(with: $0) }
    }

    func updateCurrencyOptions(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.currencyCodeKey:
            if let currencyCode = CurrencyCode(rawValue: value) {
                self.currencyCode = currencyCode
            }
        case Constants.currencyPositionKey:
            if let currencyPosition = CurrencyPosition(rawValue: value) {
                self.currencyPosition = currencyPosition
            }
        case Constants.thousandSeparatorKey:
            self.groupingSeparator = value
        case Constants.decimalSeparatorKey:
            self.decimalSeparator = value
        case Constants.numberOfDecimalsKey:
            if let numberOfDecimals = Int(value) {
                self.fractionDigits = numberOfDecimals
            }
        default:
            break
        }
    }

    enum Constants {
        static let currencyCodeKey = "woocommerce_currency"
        static let currencyPositionKey = "woocommerce_currency_pos"
        static let thousandSeparatorKey = "woocommerce_price_thousand_sep"
        static let decimalSeparatorKey = "woocommerce_price_decimal_sep"
        static let numberOfDecimalsKey = "woocommerce_price_num_decimals"
    }
}
