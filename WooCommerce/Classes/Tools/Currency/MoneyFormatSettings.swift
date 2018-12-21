import Foundation
import Yosemite

/// Site-wide settings for displaying prices/money
///
public class MoneyFormatSettings {
    /// Shared Instance
    ///
    static var shared = MoneyFormatSettings()

    /// Designates where the currency symbol is located on a formatted price
    ///
    public enum CurrencyPosition: String {
        case left = "left"
        case right = "right"
        case leftSpace = "left_space"
        case rightSpace = "right_space"
    }

    public private(set) var currencyPosition: CurrencyPosition
    public private(set) var thousandSeparator: String
    public private(set) var decimalSeparator: String
    public private(set) var numberOfDecimals: Int

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager

        let resultsController = ResultsController<StorageSiteSetting>(storageManager: storageManager, sectionNameKeyPath: nil, sortedBy: [])

        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            self?.updateFormatSetting(with: object)
        }

        return resultsController
    }()

    /// Designated Initializer:
    /// Used primarily for testing and by the convenience initializers.
    ///
    init(currencyPosition: CurrencyPosition, thousandSeparator: String, decimalSeparator: String, numberOfDecimals: Int) {
        self.currencyPosition = currencyPosition
        self.thousandSeparator = thousandSeparator
        self.decimalSeparator = decimalSeparator
        self.numberOfDecimals = numberOfDecimals
    }


    /// Convenience Initializer:
    /// Provides sane defaults for when site settings aren't available
    ///
    convenience init() {
        self.init(currencyPosition: Constants.defaultCurrencyPosition,
                  thousandSeparator: Constants.defaultThousandSeparator,
                  decimalSeparator: Constants.defaultDecimalSeparator,
                  numberOfDecimals: Constants.defaultNumberOfDecimals)
    }

    /// Convenience Initializer:
    /// This is the preferred way to create an instance with the settings coming from the site.
    ///
    convenience init(siteSettings: [SiteSetting]) {
        self.init()

        siteSettings.forEach { updateFormatSetting(with: $0) }
    }

    func beginListeningToSiteSettingsUpdates() {
        try? resultsController.performFetch()
    }

    func updateFormatSetting(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.currencyPositionKey:
            let currencyPosition = MoneyFormatSettings.CurrencyPosition(rawValue: value) ?? .left
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

private extension MoneyFormatSettings {
    enum Constants {
        static let currencyPositionKey: String = "woocommerce_currency_pos"
        static let thousandSeparatorKey: String = "woocommerce_price_thousand_sep"
        static let decimalSeparatorKey: String = "woocommerce_price_decimal_sep"
        static let numberOfDecimalsKey: String = "woocommerce_price_num_decimals"

        static let defaultCurrencyPosition = CurrencyPosition.left
        static let defaultThousandSeparator = ","
        static let defaultDecimalSeparator = "."
        static let defaultNumberOfDecimals = 2
    }
}
