import Storage

// MARK: - AppSettingsStore
//
public class AppSettingsStore: Store {
    private lazy var selectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("shipment-providers.plist")
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
        }
    }
}


// MARK: - Tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int,
                             providerName: String,
                             onCompletion: (Error?) -> Void)
    {
        guard FileManager.default.fileExists(atPath: selectedProvidersURL.path) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              onCompletion: onCompletion)
            onCompletion(nil)
            return
        }

        do {
            let data = try Data(contentsOf: selectedProvidersURL)
            let decoder = PropertyListDecoder()
            let settings = try decoder.decode([PreselectedProvider].self, from: data)
            upsertTrackingProvider(siteID: siteID,
                                   providerName: providerName,
                                   preselectedData: settings,
                                   onCompletion: onCompletion)
        } catch {
            let error = AppSettingsStoreErrors.parsePreselectedProvider
            onCompletion(error)
        }

    }

    func upsertTrackingProvider(siteID: Int,
                                providerName: String,
                                preselectedData: [PreselectedProvider],
                                onCompletion: (Error?) -> Void) {
        let newPreselectedProvider = PreselectedProvider(siteID: siteID,
                                                         providerName: providerName)

        var dataToSave = preselectedData

        if preselectedData.contains(newPreselectedProvider),
            let index = preselectedData.firstIndex(of: newPreselectedProvider) {
            dataToSave[index] = newPreselectedProvider
        } else {
            dataToSave.append(newPreselectedProvider)
        }

        write(dataToSave, onCompletion: onCompletion)
    }

    func insertNewProvider(siteID: Int,
                           providerName: String,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName)

        write([preselectedProvider], onCompletion: onCompletion)
    }

    func write(_ data: [PreselectedProvider], onCompletion: (Error?) -> Void) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: selectedProvidersURL)
        } catch {
            let error = AppSettingsStoreErrors.writePreselectedProvider
            onCompletion(error)
        }
    }
}


/// Errors
///
enum AppSettingsStoreErrors: Error {
    case parsePreselectedProvider
    case writePreselectedProvider
}
