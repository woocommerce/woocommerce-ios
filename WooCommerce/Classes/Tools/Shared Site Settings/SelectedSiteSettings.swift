import Combine
import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import WooFoundation


extension Notification.Name {

    /// Posted whenever the selectedSiteSettings are refreshed.
    ///
    public static let selectedSiteSettingsRefreshed = Notification.Name(rawValue: "selectedSiteSettingsRefreshed")
}

/// Source of site settings update.
enum SettingsUpdateSource {
    case initialLoad
    case storageChange
    case refresh
}

/// Protocol for accessing, refreshing, and observing site settings.
protocol SelectedSiteSettingsProtocol {
    var settingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never> { get }
    var siteSettings: [SiteSetting] { get }
    func refresh()
}

/// Settings for the selected Site
///
final class SelectedSiteSettings: NSObject, SelectedSiteSettingsProtocol {
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    /// CurrentValueSubject for observing site settings changes with current value behavior.
    private let settingsSubject = CurrentValueSubject<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource)?, Never>(nil)
    public var settingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never> {
        settingsSubject.compactMap { $0 }.eraseToAnyPublisher()
    }

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    public private(set) var siteSettings: [Yosemite.SiteSetting] = []

    init(stores: StoresManager = ServiceLocator.stores, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.stores = stores
        self.storageManager = storageManager

        super.init()
        configureResultsController()
    }
}

// MARK: - ResultsController
//
extension SelectedSiteSettings {

    /// Refreshes the currency settings for the current default site
    ///
    func refresh() {
        refreshResultsPredicate(source: .refresh)
    }

    /// Setup: ResultsController
    ///
    private func configureResultsController() {
        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            guard let self else { return }
            ServiceLocator.currencySettings.updateCurrencyOptions(with: object)
            self.siteSettings = self.resultsController.fetchedObjects
            guard let siteID = stores.sessionManager.defaultStoreID else {
                DDLogError("Error: no siteID found when setting site settings results.")
                return
            }
            settingsSubject.send((siteID: siteID, settings: siteSettings, source: .storageChange))
        }
        refreshResultsPredicate(source: .initialLoad)
    }

    private func refreshResultsPredicate(source: SettingsUpdateSource) {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            DDLogError("Error: no siteID found when attempting to refresh CurrencySettings results predicate.")
            return
        }

        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        let settingTypePredicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.general.rawValue)
        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingTypePredicate])
        try? resultsController.performFetch()
        let fetchedObjects = resultsController.fetchedObjects
        siteSettings = fetchedObjects
        fetchedObjects.forEach {
            ServiceLocator.currencySettings.updateCurrencyOptions(with: $0)
        }

        settingsSubject.send((siteID: siteID, settings: fetchedObjects, source: source))

        NotificationCenter.default.post(name: .selectedSiteSettingsRefreshed, object: nil)

        // Needed to correcly format the widget data.
        UserDefaults.group?[.defaultStoreCurrencySettings] = try? JSONEncoder().encode(ServiceLocator.currencySettings)
    }
}

extension CurrencySettings {
    /// Convenience Initializer:
    /// This is the preferred way to create an instance with the settings coming from the site.
    ///
    convenience init(siteSettings: [Yosemite.SiteSetting]) {
        self.init()

        siteSettings.forEach { updateCurrencyOptions(with: $0) }
    }

    func updateCurrencyOptions(with siteSetting: Yosemite.SiteSetting) {
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
