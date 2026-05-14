import Combine
import Foundation
import Yosemite
import WidgetKit
import WooFoundation
import protocol Storage.StorageManagerType

/// Mirrors the user's selectable WooCommerce sites into shared app-group `UserDefaults` so the
/// `StoreWidgetsExtension` can populate its site picker.
///
/// Listens to:
/// - `StorageSite` changes via a `ResultsController`, scoped to active WooCommerce sites.
/// - `StorageSiteSetting` changes via a `ResultsController`, scoped to general site settings —
///   the source of currency settings for non-default sites.
/// - `hiddenStoreIDs` `UserDefaults` changes via KVO — sites hidden in the host app's store
///   picker are also hidden in the widget picker.
/// - Default-site changes via `defaultStoreIDPublisher` — controls default-first ordering.
/// - `.logOutEventReceived` — clears the shared list explicitly.
///
/// Site-picker exposure is gated on WPCOM credentials. For any other authentication mode the
/// shared list is cleared, so the widget picker has no selectable sites and the existing
/// default-site rendering path is used unchanged.
final class WidgetSiteListSyncManager {
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let widgetSiteListStore: WidgetSiteListStore
    private let widgetSiteCurrencyCache: WidgetSiteCurrencyCache
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter

    private var hasStarted = false
    private var hiddenStoreIDsObservation: NSKeyValueObservation?
    private var logOutObserver: NSObjectProtocol?
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var sitesResultsController: ResultsController<StorageSite> = {
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageSite.name, ascending: true)
        return ResultsController<StorageSite>(storageManager: storageManager,
                                              matching: predicate,
                                              sortedBy: [sortDescriptor])
    }()

    private lazy var siteSettingsResultsController: ResultsController<StorageSiteSetting> = {
        let predicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.general.rawValue)
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: true)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager,
                                                     matching: predicate,
                                                     sortedBy: [sortDescriptor])
    }()

    init(stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         widgetSiteListStore: WidgetSiteListStore = WidgetSiteListStore(),
         widgetSiteCurrencyCache: WidgetSiteCurrencyCache = WidgetSiteCurrencyCache(),
         userDefaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default) {
        self.stores = stores
        self.storageManager = storageManager
        self.widgetSiteListStore = widgetSiteListStore
        self.widgetSiteCurrencyCache = widgetSiteCurrencyCache
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
    }

    deinit {
        teardownObservers()
    }

    /// Begins observing storage and writes the initial list. Idempotent.
    func start() {
        guard !hasStarted else {
            return
        }
        hasStarted = true

        configureSitesResultsController()
        configureSiteSettingsResultsController()
        configureHiddenStoreIDsObservation()
        configureDefaultStoreIDObservation()
        configureLogOutObservation()

        rebuildAndPersist()
    }

    /// Tears down observers and clears the shared list. Idempotent.
    func stop() {
        guard hasStarted else {
            return
        }

        teardownObservers()
        hasStarted = false

        widgetSiteListStore.clear()
        widgetSiteCurrencyCache.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Observers
private extension WidgetSiteListSyncManager {
    func configureSitesResultsController() {
        sitesResultsController.onDidChangeContent = { [weak self] in
            self?.rebuildAndPersist()
        }
        sitesResultsController.onDidResetContent = { [weak self] in
            self?.rebuildAndPersist()
        }
        try? sitesResultsController.performFetch()
    }

    func configureSiteSettingsResultsController() {
        siteSettingsResultsController.onDidChangeContent = { [weak self] in
            self?.rebuildAndPersist()
        }
        siteSettingsResultsController.onDidResetContent = { [weak self] in
            self?.rebuildAndPersist()
        }
        try? siteSettingsResultsController.performFetch()
    }

    func configureHiddenStoreIDsObservation() {
        hiddenStoreIDsObservation = userDefaults.observe(\.hiddenStoreIDs, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.rebuildAndPersist()
            }
        }
    }

    func configureDefaultStoreIDObservation() {
        stores.sessionManager.defaultStoreIDPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildAndPersist()
            }
            .store(in: &subscriptions)
    }

    func configureLogOutObservation() {
        logOutObserver = notificationCenter.addObserver(forName: .logOutEventReceived,
                                                        object: nil,
                                                        queue: .main) { [weak self] _ in
            self?.widgetSiteListStore.clear()
            self?.widgetSiteCurrencyCache.clear()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func teardownObservers() {
        // Avoid touching the lazy `ResultsController` properties when the manager was never
        // started — accessing them would force them to instantiate at teardown.
        if hasStarted {
            sitesResultsController.onDidChangeContent = nil
            sitesResultsController.onDidResetContent = nil
            siteSettingsResultsController.onDidChangeContent = nil
            siteSettingsResultsController.onDidResetContent = nil
        }
        hiddenStoreIDsObservation?.invalidate()
        hiddenStoreIDsObservation = nil
        if let logOutObserver {
            notificationCenter.removeObserver(logOutObserver)
        }
        logOutObserver = nil
        subscriptions.removeAll()
    }
}

// MARK: - List rebuild
private extension WidgetSiteListSyncManager {
    func rebuildAndPersist() {
        let sites = buildSites()
        widgetSiteListStore.save(sites)
        removeCachedCurrencySettingsForAuthoritativeSites(sites)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func buildSites() -> [WidgetSite] {
        guard exposesSiteSelector else {
            return []
        }

        let hiddenStoreIDs = Set(userDefaults.hiddenStoreIDs)
        let defaultStoreID = stores.sessionManager.defaultStoreID
        let currencySettingsBySiteID = currencySettingsBySiteID()

        return sitesResultsController.fetchedObjects
            .filter { !hiddenStoreIDs.contains($0.siteID) }
            .map { site in
                WidgetSite(siteID: site.siteID,
                           name: site.name,
                           timezoneIdentifier: site.timezone,
                           gmtOffset: site.gmtOffset,
                           currencySettings: currencySettingsBySiteID[site.siteID])
            }
            .sorted { lhs, rhs in
                let lhsIsDefault = lhs.siteID == defaultStoreID
                let rhsIsDefault = rhs.siteID == defaultStoreID
                if lhsIsDefault != rhsIsDefault {
                    return lhsIsDefault
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func currencySettingsBySiteID() -> [Int64: CurrencySettings] {
        let settingsBySiteID = Dictionary(grouping: siteSettingsResultsController.fetchedObjects, by: \.siteID)
        return settingsBySiteID.compactMapValues { settings in
            currencySettings(from: settings)
        }
    }

    /// Returns `CurrencySettings` only when all keys required by the widget formatter are present
    /// for this site; otherwise returns `nil` so the widget can fall back to the default site's
    /// currency settings at render time.
    func currencySettings(from siteSettings: [SiteSetting]) -> CurrencySettings? {
        CurrencySettings.completeSettings(siteSettings: siteSettings)
    }

    func removeCachedCurrencySettingsForAuthoritativeSites(_ sites: [WidgetSite]) {
        sites
            .filter { $0.currencySettings != nil }
            .forEach { widgetSiteCurrencyCache.removeCurrencySettings(forSiteID: $0.siteID) }
    }

    var exposesSiteSelector: Bool {
        guard case .wpcom = stores.sessionManager.defaultCredentials else {
            return false
        }
        return true
    }
}
