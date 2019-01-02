import Foundation
import Yosemite

/// Site-wide settings for displaying prices/money
///
public class CurrencySettings {
    /// Shared Instance
    ///
    static var shared = CurrencySettings()

    /// Public variables, privately set
    ///
    public private(set) var currencyCode: Currency.Code
    public private(set) var currencyPosition: Currency.Position
    public private(set) var thousandSeparator: String
    public private(set) var decimalSeparator: String
    public private(set) var numberOfDecimals: Int

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager

        let resultsController = ResultsController<StorageSiteSetting>(storageManager: storageManager, sectionNameKeyPath: nil, sortedBy: [])

        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            self?.updateCurrencyOptions(with: object)
        }

        return resultsController
    }()

    /// Designated Initializer:
    /// Used primarily for testing and by the convenience initializers.
    ///
    init(currencyCode: Currency.Code, currencyPosition: Currency.Position, thousandSeparator: String, decimalSeparator: String, numberOfDecimals: Int) {
        self.currencyCode = currencyCode
        self.currencyPosition = currencyPosition
        self.thousandSeparator = thousandSeparator
        self.decimalSeparator = decimalSeparator
        self.numberOfDecimals = numberOfDecimals
    }


    /// Convenience Initializer:
    /// Provides sane defaults for when site settings aren't available
    ///
    convenience init() {
        self.init(currencyCode: Constants.defaultCurrencyCode,
                  currencyPosition: Constants.defaultCurrencyPosition,
                  thousandSeparator: Constants.defaultThousandSeparator,
                  decimalSeparator: Constants.defaultDecimalSeparator,
                  numberOfDecimals: Constants.defaultNumberOfDecimals)
    }

    /// Convenience Initializer:
    /// This is the preferred way to create an instance with the settings coming from the site.
    ///
    convenience init(siteSettings: [SiteSetting]) {
        self.init()

        siteSettings.forEach { updateCurrencyOptions(with: $0) }
    }

    func beginListeningToSiteSettingsUpdates() {
        try? resultsController.performFetch()
    }

    func updateCurrencyOptions(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.currencyCodeKey:
            let currencyCode = Currency.Code(rawValue: value) ?? .USD
            self.currencyCode = currencyCode
        case Constants.currencyPositionKey:
            let currencyPosition = Currency.Position(rawValue: value) ?? .left
            self.currencyPosition = currencyPosition
        case Constants.thousandSeparatorKey:
            self.thousandSeparator = value
        case Constants.decimalSeparatorKey:
            self.decimalSeparator = value
        case Constants.numberOfDecimalsKey:
            let numberOfDecimals = Int(value) ?? Constants.defaultNumberOfDecimals
            self.numberOfDecimals = numberOfDecimals
        default:
            break
        }
    }
}

private extension CurrencySettings {
    enum Constants {
        static let currencyCodeKey = "woocommerce_currency"
        static let currencyPositionKey = "woocommerce_currency_pos"
        static let thousandSeparatorKey = "woocommerce_price_thousand_sep"
        static let decimalSeparatorKey = "woocommerce_price_decimal_sep"
        static let numberOfDecimalsKey = "woocommerce_price_num_decimals"

        static let defaultCurrencyCode = Currency.Code.USD
        static let defaultCurrencyPosition = Currency.Position.left
        static let defaultThousandSeparator = ","
        static let defaultDecimalSeparator = "."
        static let defaultNumberOfDecimals = 2
    }
}
