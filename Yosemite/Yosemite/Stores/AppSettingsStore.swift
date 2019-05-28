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
        }
    }
}


// MARK: - Shipment tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int,
                             providerName: String,
                             onCompletion: (Error?) -> Void) {
        guard FileManager.default.fileExists(atPath: selectedProvidersURL.path) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              toFileURL: selectedProvidersURL,
                              onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        do {
            let data = try fileStorage.data(for: selectedProvidersURL)
            let decoder = PropertyListDecoder()
            let settings = try decoder.decode([PreselectedProvider].self, from: data)
            upsertTrackingProvider(siteID: siteID,
                                   providerName: providerName,
                                   preselectedData: settings,
                                   toFileURL: selectedProvidersURL,
                                   onCompletion: onCompletion)
        } catch {
            let error = AppSettingsStoreErrors.parsePreselectedProvider
            onCompletion(error)

            DDLogError("⛔️ Saving a tracking provider locally failed: siteID \(siteID). Error: \(error)")
        }

    }

    func addCustomTrackingProvider(siteID: Int,
                             providerName: String,
                             providerURL: String,
                             onCompletion: (Error?) -> Void) {
        guard FileManager.default.fileExists(atPath: customSelectedProvidersURL.path) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              providerURL: providerURL,
                              toFileURL: customSelectedProvidersURL,
                              onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        do {
            let data = try fileStorage.data(for: customSelectedProvidersURL)
            let decoder = PropertyListDecoder()
            let settings = try decoder.decode([PreselectedProvider].self, from: data)
            upsertTrackingProvider(siteID: siteID,
                                   providerName: providerName,
                                   providerURL: providerURL,
                                   preselectedData: settings,
                                   toFileURL: selectedProvidersURL,
                                   onCompletion: onCompletion)
        } catch {
            let error = AppSettingsStoreErrors.parsePreselectedProvider
            onCompletion(error)

            DDLogError("⛔️ Saving a tracking provider locally failed: siteID \(siteID). Error: \(error)")
        }
    }

    func loadTrackingProvider(siteID: Int,
                              onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void) {
        guard let allSavedProviders = read() else {
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

        write(dataToSave, to: toFileURL, onCompletion: onCompletion)
    }

    func insertNewProvider(siteID: Int,
                           providerName: String,
                           providerURL: String? = nil,
                           toFileURL: URL,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName,
                                                      providerURL: providerURL)

        write([preselectedProvider], to: toFileURL, onCompletion: onCompletion)
    }

    func write(_ data: [PreselectedProvider], to fileURL: URL, onCompletion: (Error?) -> Void) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let encodedData = try encoder.encode(data)
            try fileStorage.write(encodedData, to: fileURL)
            onCompletion(nil)
        } catch {
            let error = AppSettingsStoreErrors.writePreselectedProvider
            onCompletion(error)
        }
    }

    func read() -> [PreselectedProvider]? {
        do {
            let data = try fileStorage.data(for: selectedProvidersURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode([PreselectedProvider].self, from: data)
        } catch {
            return nil
        }
    }

    func resetStoredProviders(onCompletion: ((Error?) -> Void)? = nil) {
        do {
            try fileStorage.deleteFile(at: selectedProvidersURL)
            onCompletion?(nil)
        } catch {
            let error = AppSettingsStoreErrors.deletePreselectedProvider
            onCompletion?(error)
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
}


// MARK: - Constants

/// Constants
///
private enum Constants {
    static let shipmentProvidersFileName = "shipment-providers.plist"
    static let customShipmentProvidersFileName = "custom-shipment-providers.plist"
}
