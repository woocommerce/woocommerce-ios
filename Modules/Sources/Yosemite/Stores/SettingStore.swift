import Foundation
import Networking
import Storage


// MARK: - SettingStore
//
public class SettingStore: Store {
    private let siteSettingsRemote: SiteSettingsRemote
    private let siteAPIRemote: SiteAPIRemote
    private let methods: SettingStoreMethods

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.siteSettingsRemote = SiteSettingsRemote(network: network)
        self.siteAPIRemote = SiteAPIRemote(network: network)
        self.methods = SettingStoreMethods(storageManager: storageManager, network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SettingAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? SettingAction else {
            assertionFailure("SettingStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeGeneralSiteSettings(let siteID, let onCompletion):
            methods.synchronizeGeneralSiteSettings(siteID: siteID, onCompletion: onCompletion)
        case .synchronizeProductSiteSettings(let siteID, let onCompletion):
            methods.synchronizeProductSiteSettings(siteID: siteID, onCompletion: onCompletion)
        case .retrieveSiteAPI(let siteID, let onCompletion):
            methods.retrieveSiteAPI(siteID: siteID, onCompletion: onCompletion)
        case let .retrievePointOfSaleSettings(siteID, onCompletion):
            Task { @MainActor in
                do {
                    let settings = try await methods.retrievePointOfSaleSettings(siteID: siteID)
                    onCompletion(.success(settings))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        case let .retrieveCouponSetting(siteID, onCompletion):
            methods.retrieveCouponSetting(siteID: siteID, onCompletion: onCompletion)
        case let .enableCouponSetting(siteID, onCompletion):
            methods.enableCouponSetting(siteID: siteID, onCompletion: onCompletion)
        case let .retrieveAnalyticsSetting(siteID, onCompletion):
            methods.retrieveAnalyticsSetting(siteID: siteID, onCompletion: onCompletion)
        case let .enableAnalyticsSetting(siteID, onCompletion):
            methods.enableAnalyticsSetting(siteID: siteID, onCompletion: onCompletion)
        case let .retrieveTaxBasedOnSetting(siteID: siteID, onCompletion: onCompletion):
            methods.retrieveTaxBasedOnSetting(siteID: siteID, onCompletion: onCompletion)
        case let .isFeatureEnabled(siteID: siteID, feature: feature, onCompletion: onCompletion):
            Task { @MainActor in
                do {
                    let isEnabled = try await methods.isFeatureEnabled(siteID: siteID, feature: feature)
                    onCompletion(.success(isEnabled))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        case let .retrieveAnalyticsOrderDateType(siteID, onCompletion):
            Task { @MainActor in
                do {
                    let dateType = try await methods.retrieveAnalyticsOrderDateType(siteID: siteID)
                    onCompletion(.success(dateType))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        case let .updateAnalyticsOrderDateType(siteID, value, onCompletion):
            Task { @MainActor in
                do {
                    let dateType = try await methods.updateAnalyticsOrderDateType(siteID: siteID, value: value)
                    onCompletion(.success(dateType))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Unit Testing Helpers
//
extension SettingStore {
    func upsertStoredGeneralSiteSettings(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], in storage: StorageType) {
        methods.upsertStoredGeneralSiteSettings(siteID: siteID, readOnlySiteSettings: readOnlySiteSettings, in: storage)
    }

    /// Unit Testing Helper: Updates or Inserts the specified **product** ReadOnly SiteSetting entities in the provided Storage instance.
    ///
    func upsertStoredProductSiteSettings(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], in storage: StorageType) {
        methods.upsertStoredProductSiteSettings(siteID: siteID, readOnlySiteSettings: readOnlySiteSettings, in: storage)
    }
}

extension TaxBasedOnSetting {
    init?(backendValue: String) {
        switch backendValue {
        case "shipping":
            self = .customerShippingAddress
        case "billing":
            self = .customerBillingAddress
        case "base":
            self = .shopBaseAddress
        default:
            return nil
        }
    }
}
