import Foundation

/// Protocol for SiteSettingsRemote to enable testing.
public protocol SiteSettingsRemoteProtocol {
    func setFeature(for siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool
}

/// Features that can be enabled/disabled in core, under WC Settings > Advanced > Features.
public enum SiteSettingsFeature {
    case pointOfSale
}

/// SiteSettings: Remote Endpoints
///
public class SiteSettingsRemote: Remote {

    /// Retrieves all of the general `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the general settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadGeneralSettings(for siteID: Int64, completion: @escaping ([SiteSetting]?, Error?) -> Void) {
        let path = Constants.siteSettingsPath + Constants.generalSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.general)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the product `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the product settings.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadProductSettings(for siteID: Int64, completion: @escaping ([SiteSetting]?, Error?) -> Void) {
        let path = Constants.siteSettingsPath + Constants.productSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.product)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the point of sale `SiteSetting`s for a given site.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the point of sale settings.
    /// - Returns: An array of SiteSettings, specific to point of sale.
    /// - Throws: Error if the request fails.
    ///
    public func loadPointOfSaleSettings(for siteID: Int64) async throws -> [SiteSetting] {
        let path = Constants.siteSettingsPath + Constants.pointOfSaleSettingsGroup
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingsMapper(siteID: siteID, settingsGroup: SiteSettingGroup.pointOfSale)

        return try await enqueue(request, mapper: mapper)
    }

    /// Retrieve detail for a single setting for a given site
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the setting.
    ///   - settingGroup: The group the setting belong to.
    ///   - settingID: ID of the setting.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSetting(for siteID: Int64, settingGroup: SiteSettingGroup, settingID: String, completion: @escaping (Result<SiteSetting, Error>) -> Void) {
        let path = Constants.siteSettingsPath + settingGroup.rawValue + "/" + settingID
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: settingGroup)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Update value for a single setting for a given site
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll update setting.
    ///   - settingGroup: The group the setting belong to.
    ///   - settingID: ID of the setting.
    ///   - value: New value for the setting.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func updateSetting(for siteID: Int64,
                              settingGroup: SiteSettingGroup,
                              settingID: String,
                              value: String,
                              completion: @escaping (Result<SiteSetting, Error>) -> Void) {
        let parameters: [String: Any] = [Constants.valueParameter: value]
        let path = Constants.siteSettingsPath + settingGroup.rawValue + "/" + settingID
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .put,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: settingGroup)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Checks if a specific feature is enabled in the site WC settings.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll check the feature status.
    ///   - feature: The feature to check.
    /// - Returns: A boolean indicating if the feature is enabled.
    /// - Throws: Error if the request fails or the setting cannot be parsed.
    ///
    public func isFeatureEnabled(for siteID: Int64, feature: SiteSettingsFeature) async throws -> Bool {
        let path = Constants.siteSettingsPath + Constants.advancedSettingsGroup + "/woocommerce_feature_\(feature.rawValue)_enabled"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: .advanced)
        let response = try await enqueue(request, mapper: mapper)
        switch response.value {
        case Constants.featureEnabledValue:
            return true
        case Constants.featureDisabledValue:
            return false
        default:
            throw SiteSettingsRemoteError.invalidResponse
        }
    }

    /// Enables or disables a specific feature in the site WC settings.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll update the feature status.
    ///   - feature: The feature to enable or disable.
    ///   - enabled: Whether the feature should be enabled (true) or disabled (false).
    /// - Returns: A boolean indicating the updated feature status.
    /// - Throws: Error if the request fails.
    ///
    public func setFeature(for siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool {
        let value = enabled ? Constants.featureEnabledValue : Constants.featureDisabledValue
        let parameters: [String: Any] = [Constants.valueParameter: value]
        let path = Constants.siteSettingsPath + Constants.advancedSettingsGroup + "/woocommerce_feature_\(feature.rawValue)_enabled"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .put,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SiteSettingMapper(siteID: siteID, settingsGroup: .advanced)
        let response = try await enqueue(request, mapper: mapper)
        switch response.value {
        case Constants.featureEnabledValue:
            return true
        case Constants.featureDisabledValue:
            return false
        default:
            throw SiteSettingsRemoteError.invalidResponse
        }
    }
}

extension SiteSettingsRemote: SiteSettingsRemoteProtocol {}

public extension SiteSettingsFeature {
    var rawValue: String {
        switch self {
        case .pointOfSale:
            return "point_of_sale"
        }
    }
}

// MARK: - Constants!
//
private extension SiteSettingsRemote {
    enum Constants {
        static let siteSettingsPath: String       = "settings/"
        static let generalSettingsGroup: String   = "general"
        static let productSettingsGroup: String   = "products"
        static let advancedSettingsGroup: String   = "advanced"
        static let pointOfSaleSettingsGroup: String = "point-of-sale"
        static let valueParameter: String = "value"
        static let featureEnabledValue: String = "yes"
        static let featureDisabledValue: String = "no"
    }
}

public enum SiteSettingsRemoteError: Error {
    case invalidResponse
}
