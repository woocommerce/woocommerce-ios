import Storage
import Networking

// MARK: - AppSettingsStore
//
public class AppSettingsStore: Store {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    /// Designated initaliser
    ///
    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                fileStorage: FileStorage) {
        self.fileStorage = fileStorage
        super.init(dispatcher: dispatcher,
                   storageManager: storageManager,
                   network: NullNetwork())
    }

    /// URL to the plist file that we use to store the user selected
    /// shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var selectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.shipmentProvidersFileName)
    }()

    /// URL to the plist file that we use to store the user selected
    /// custom shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var customSelectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.customShipmentProvidersFileName)
    }()

    /// URL to the plist file that we use to determine the visibility for stats version banner.
    ///
    private lazy var statsVersionBannerVisibilityURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionBannerVisibilityFileName)
    }()

    /// URL to the plist file that we use to store the eligible stats version.
    ///
    private lazy var statsVersionEligibleURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionEligibleFileName)
    }()

    /// URL to the plist file that we use to store the stats version displayed on Dashboard UI.
    ///
    private lazy var statsVersionLastShownURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionLastShownFileName)
    }()

    /// URL to the plist file that we use to determine the visibility for Product features.
    ///
    private lazy var productsVisibilityURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.productsVisibilityFileName)
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AppSettingsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AppSettingsAction else {
            assertionFailure("ShipmentStore received an unsupported action")
            return
        }

        switch action {
        case .addTrackingProvider(let siteID, let providerName, let onCompletion):
            addTrackingProvider(siteID: siteID,
                                providerName: providerName,
                                onCompletion: onCompletion)
        case .loadTrackingProvider(let siteID, let onCompletion):
            loadTrackingProvider(siteID: siteID,
                                 onCompletion: onCompletion)
        case .addCustomTrackingProvider(let siteID,
                                        let providerName,
                                        let providerURL,
                                        let onCompletion):
            addCustomTrackingProvider(siteID: siteID,
                                      providerName: providerName,
                                      providerURL: providerURL,
                                      onCompletion: onCompletion)
        case .loadCustomTrackingProvider(let siteID,
                                         let onCompletion):
            loadCustomTrackingProvider(siteID: siteID,
                                        onCompletion: onCompletion)
        case .resetStoredProviders(let onCompletion):
            resetStoredProviders(onCompletion: onCompletion)
        case .loadStatsVersionEligible(let siteID, let onCompletion):
            loadStatsVersionEligible(siteID: siteID, onCompletion: onCompletion)
        case .setStatsVersionEligible(let siteID, let statsVersion):
            setStatsVersionEligible(siteID: siteID, statsVersion: statsVersion)
        case .setStatsVersionLastShown(let siteID, let statsVersion), .setStatsVersionPreference(let siteID, let statsVersion):
            setStatsVersionLastShownOrFromUserPreference(siteID: siteID, statsVersion: statsVersion)
        case .loadInitialStatsVersionToShow(let siteID, let onCompletion):
            loadInitialStatsVersionToShow(siteID: siteID, onCompletion: onCompletion)
        case .loadStatsVersionBannerVisibility(let banner, let onCompletion):
            loadStatsVersionBannerVisibility(banner: banner, onCompletion: onCompletion)
        case .setStatsVersionBannerVisibility(let banner, let shouldShowBanner):
            setStatsVersionBannerVisibility(banner: banner, shouldShowBanner: shouldShowBanner)
        case .loadProductsVisibility(let onCompletion):
            loadProductsVisibility(onCompletion: onCompletion)
        case .setProductsVisibility(let isVisible, let onCompletion):
            setProductsVisibility(isVisible: isVisible, onCompletion: onCompletion)
        case .resetStatsVersionStates:
            resetStatsVersionStates()
        }
    }
}


// MARK: - Shipment tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int64,
                             providerName: String,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    fileURL: selectedProvidersURL,
                    onCompletion: onCompletion)

    }

    func addCustomTrackingProvider(siteID: Int64,
                             providerName: String,
                             providerURL: String?,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    providerURL: providerURL,
                    fileURL: customSelectedProvidersURL,
                    onCompletion: onCompletion)
    }

    func addProvider(siteID: Int64,
                     providerName: String,
                     providerURL: String? = nil,
                     fileURL: URL,
                     onCompletion: (Error?) -> Void) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              providerURL: providerURL,
                              toFileURL: fileURL,
                              onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        do {
            let data = try fileStorage.data(for: fileURL)
            let decoder = PropertyListDecoder()
            let settings = try decoder.decode([PreselectedProvider].self, from: data)
            upsertTrackingProvider(siteID: siteID,
                                   providerName: providerName,
                                   preselectedData: settings,
                                   toFileURL: fileURL,
                                   onCompletion: onCompletion)
        } catch {
            let error = AppSettingsStoreErrors.parsePreselectedProvider
            onCompletion(error)

            DDLogError("⛔️ Saving a tracking provider locally failed: siteID \(siteID). Error: \(error)")
        }
    }

    func loadTrackingProvider(siteID: Int64,
                              onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void) {
        guard let allSavedProviders = read(from: selectedProvidersURL) as [PreselectedProvider]? else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
                $0.siteID == siteID
            }.first?.providerName

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let provider = storageManager
            .viewStorage
            .loadShipmentTrackingProvider(siteID: siteID,
                                          name: name)

        onCompletion(provider?.toReadOnly(), provider?.group?.toReadOnly(), nil)
    }

    func loadCustomTrackingProvider(siteID: Int64,
                              onCompletion: (ShipmentTrackingProvider?, Error?) -> Void) {
        guard let allSavedProviders = read(from: customSelectedProvidersURL) as [PreselectedProvider]? else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
            $0.siteID == siteID
            }.first?.providerName

        let providerURL = allSavedProviders.filter {
            $0.siteID == siteID
            }.first?.providerURL

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let customProvider = ShipmentTrackingProvider(siteID: siteID,
                                                      name: name,
                                                      url: providerURL ?? "")
        onCompletion(customProvider, nil)
    }

    func upsertTrackingProvider(siteID: Int64,
                                providerName: String,
                                providerURL: String? = nil,
                                preselectedData: [PreselectedProvider],
                                toFileURL: URL,
                                onCompletion: (Error?) -> Void) {
        let newPreselectedProvider = PreselectedProvider(siteID: siteID,
                                                         providerName: providerName,
                                                         providerURL: providerURL)

        var dataToSave = preselectedData

        if preselectedData.contains(newPreselectedProvider),
            let index = preselectedData.firstIndex(of: newPreselectedProvider) {
            dataToSave[index] = newPreselectedProvider
        } else {
            dataToSave.append(newPreselectedProvider)
        }

        write(dataToSave, to: toFileURL, onCompletion: onCompletion)
    }

    func insertNewProvider(siteID: Int64,
                           providerName: String,
                           providerURL: String? = nil,
                           toFileURL: URL,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName,
                                                      providerURL: providerURL)

        write([preselectedProvider], to: toFileURL, onCompletion: onCompletion)
    }

    func resetStoredProviders(onCompletion: ((Error?) -> Void)? = nil) {
        do {
            try fileStorage.deleteFile(at: selectedProvidersURL)
            try fileStorage.deleteFile(at: customSelectedProvidersURL)
            onCompletion?(nil)
        } catch {
            let error = AppSettingsStoreErrors.deletePreselectedProvider
            onCompletion?(error)
        }
    }
}

// MARK: - Stats version
//
private extension AppSettingsStore {
    func setStatsVersionLastShownOrFromUserPreference(siteID: Int64,
                                                      statsVersion: StatsVersion) {
        set(statsVersion: statsVersion, for: siteID, to: statsVersionLastShownURL, onCompletion: { error in
            if let error = error {
                DDLogError("⛔️ Saving the last shown stats version failed: siteID \(siteID). Error: \(error)")
            }
        })
    }

    func setStatsVersionEligible(siteID: Int64,
                                 statsVersion: StatsVersion) {
        set(statsVersion: statsVersion, for: siteID, to: statsVersionEligibleURL, onCompletion: { error in
            if let error = error {
                DDLogError("⛔️ Saving the eligible stats version to \(statsVersion) failed: siteID \(siteID). Error: \(error)")
            }
        })
    }

    func loadInitialStatsVersionToShow(siteID: Int64, onCompletion: (StatsVersion?) -> Void) {
        guard let existingData: StatsVersionBySite = read(from: statsVersionLastShownURL),
            let statsVersion = existingData.statsVersionBySite[siteID] else {
            onCompletion(nil)
            return
        }
        onCompletion(statsVersion)
    }

    func loadStatsVersionEligible(siteID: Int64, onCompletion: (StatsVersion?) -> Void) {
        guard let existingData: StatsVersionBySite = read(from: statsVersionEligibleURL),
            let statsVersion = existingData.statsVersionBySite[siteID] else {
                onCompletion(nil)
                return
        }
        onCompletion(statsVersion)
    }

    func set(statsVersion: StatsVersion, for siteID: Int64, to fileURL: URL, onCompletion: (Error?) -> Void) {
        guard let existingData: StatsVersionBySite = read(from: fileURL) else {
            let statsVersionBySite: StatsVersionBySite = StatsVersionBySite(statsVersionBySite: [siteID: statsVersion])
            write(statsVersionBySite, to: fileURL, onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        var statsVersionBySite = existingData.statsVersionBySite
        statsVersionBySite[siteID] = statsVersion
        write(StatsVersionBySite(statsVersionBySite: statsVersionBySite), to: fileURL, onCompletion: onCompletion)
    }

    func loadStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner,
                                         onCompletion: (Bool) -> Void) {
        guard let existingData: StatsVersionBannerVisibility = read(from: statsVersionBannerVisibilityURL),
            let shouldShowBanner = existingData.visibilityByBanner[banner] else {
                onCompletion(true)
                return
        }
        onCompletion(shouldShowBanner)
    }

    func setStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner,
                                         shouldShowBanner: Bool) {
        let fileURL = statsVersionBannerVisibilityURL
        guard let existingData: StatsVersionBannerVisibility = read(from: statsVersionBannerVisibilityURL) else {
            let statsVersionBySite: StatsVersionBannerVisibility = StatsVersionBannerVisibility(visibilityByBanner: [banner: shouldShowBanner])
            write(statsVersionBySite, to: fileURL, onCompletion: { _ in })
            return
        }

        var visibilityByBanner = existingData.visibilityByBanner
        visibilityByBanner[banner] = shouldShowBanner
        write(StatsVersionBannerVisibility(visibilityByBanner: visibilityByBanner), to: fileURL, onCompletion: { _ in })
    }

    func loadProductsVisibility(onCompletion: (Bool) -> Void) {
        guard let existingData: ProductsVisibilityPListWrapper = read(from: productsVisibilityURL) else {
            onCompletion(false)
            return
        }
        onCompletion(existingData.isVisible)
    }

    func setProductsVisibility(isVisible: Bool, onCompletion: () -> Void) {
        let fileURL = productsVisibilityURL
        let visibilityWrapper = ProductsVisibilityPListWrapper(isVisible: isVisible)
        write(visibilityWrapper, to: fileURL) { error in
            if let error = error {
                DDLogError("⛔️ Saving the Products visibility to \(isVisible) failed: \(error)")
            }
            onCompletion()
        }
    }

    func resetStatsVersionStates() {
        do {
            try fileStorage.deleteFile(at: statsVersionBannerVisibilityURL)
            try fileStorage.deleteFile(at: statsVersionEligibleURL)
            try fileStorage.deleteFile(at: statsVersionLastShownURL)
        } catch {
            let error = AppSettingsStoreErrors.deleteStatsVersionStates
            DDLogError("⛔️ Deleting the stats version files failed. Error: \(error)")
        }
    }
}

// MARK: - PList decoding/encoding from and to file storage
//
private extension AppSettingsStore {
    func read<T: Decodable>(from url: URL) -> T? {
        do {
            let data = try fileStorage.data(for: url)
            let decoder = PropertyListDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func write<T: Encodable>(_ data: T, to fileURL: URL, onCompletion: (Error?) -> Void) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let encodedData = try encoder.encode(data)
            try fileStorage.write(encodedData, to: fileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }
}


// MARK: - Errors

/// Errors
///
enum AppSettingsStoreErrors: Error {
    case parsePreselectedProvider
    case writePreselectedProvider
    case readPreselectedProvider
    case deletePreselectedProvider
    case readPListFromFileStorage
    case writePListToFileStorage
    case deleteStatsVersionStates
}


// MARK: - Constants

/// Constants
///
private enum Constants {
    static let shipmentProvidersFileName = "shipment-providers.plist"
    static let customShipmentProvidersFileName = "custom-shipment-providers.plist"
    static let statsVersionBannerVisibilityFileName = "stats-version-banner-visibility.plist"
    static let statsVersionEligibleFileName = "stats-version-eligible.plist"
    static let statsVersionLastShownFileName = "stats-version-last-shown.plist"
    static let productsVisibilityFileName = "products-visibility.plist"
}
