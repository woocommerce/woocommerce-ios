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

    /// URL to the plist file that we use to store the stats version displayed on Dashboard UI.
    ///
    private lazy var statsVersionLastShownURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionLastShownFileName)
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
        case .setStatsVersionLastShown(let siteID, let statsVersion):
            setStatsVersionLastShown(siteID: siteID, statsVersion: statsVersion)
        case .loadStatsVersionLastShown(let siteID, let onCompletion):
            loadStatsVersionLastShown(siteID: siteID, onCompletion: onCompletion)
        case .resetStatsVersionStates:
            resetStatsVersionStates()
        }
    }
}


// MARK: - Shipment tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int,
                             providerName: String,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    fileURL: selectedProvidersURL,
                    onCompletion: onCompletion)

    }

    func addCustomTrackingProvider(siteID: Int,
                             providerName: String,
                             providerURL: String?,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    providerURL: providerURL,
                    fileURL: customSelectedProvidersURL,
                    onCompletion: onCompletion)
    }

    func addProvider(siteID: Int,
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

    func loadTrackingProvider(siteID: Int,
                              onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void) {
        guard let allSavedProviders = readPList(from: selectedProvidersURL) as [PreselectedProvider]? else {
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

    func loadCustomTrackingProvider(siteID: Int,
                              onCompletion: (ShipmentTrackingProvider?, Error?) -> Void) {
        guard let allSavedProviders = readPList(from: customSelectedProvidersURL) as [PreselectedProvider]? else {
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

    func upsertTrackingProvider(siteID: Int,
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

        writePList(dataToSave, to: toFileURL, onCompletion: onCompletion)
    }

    func insertNewProvider(siteID: Int,
                           providerName: String,
                           providerURL: String? = nil,
                           toFileURL: URL,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName,
                                                      providerURL: providerURL)

        writePList([preselectedProvider], to: toFileURL, onCompletion: onCompletion)
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
    func setStatsVersionLastShown(siteID: Int,
                                  statsVersion: StatsVersion) {
        set(statsVersion: statsVersion, for: siteID, to: statsVersionLastShownURL, onCompletion: { error in
            if let error = error {
                DDLogError("⛔️ Saving the last shown stats version failed: siteID \(siteID). Error: \(error)")
            }
        })
    }

    func loadStatsVersionLastShown(siteID: Int, onCompletion: (StatsVersion?) -> Void) {
        guard let existingData: StatsVersionBySite = readPList(from: statsVersionLastShownURL),
            let statsVersion = existingData.statsVersionBySite[siteID] else {
            onCompletion(nil)
            return
        }
        onCompletion(statsVersion)
    }

    func set(statsVersion: StatsVersion, for siteID: Int, to fileURL: URL, onCompletion: (Error?) -> Void) {
        guard let existingData: StatsVersionBySite = readPList(from: fileURL) else {
            let statsVersionBySite: StatsVersionBySite = StatsVersionBySite(statsVersionBySite: [siteID: statsVersion])
            writePList(statsVersionBySite, to: fileURL, onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        var statsVersionBySite = existingData.statsVersionBySite
        statsVersionBySite[siteID] = statsVersion
        writePList(StatsVersionBySite(statsVersionBySite: statsVersionBySite), to: fileURL, onCompletion: onCompletion)
    }

    func resetStatsVersionStates() {
        do {
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
    func readPList<T: Decodable>(from url: URL) -> T? {
        do {
            let data = try fileStorage.data(for: url)
            let decoder = PropertyListDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func writePList<T: Encodable>(_ data: T, to fileURL: URL, onCompletion: (Error?) -> Void) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let encodedData = try encoder.encode(data)
            try fileStorage.write(encodedData, to: fileURL)
            onCompletion(nil)
        } catch {
            let error = AppSettingsStoreErrors.writePListToFileStorage
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
    static let statsVersionLastShownFileName = "stats-version-last-shown.plist"
}
