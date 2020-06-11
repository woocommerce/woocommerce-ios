import Foundation
import KeychainAccess
import Networking

// WidgetExtensionService class
// Save, Load and Remove credentials used by Extensions of the Woo app, like the TodayStatsWidget
//
final class WidgetExtensionService: NSObject {

    /// Returns the Credentials, if any, under the related App Groups.
    ///
    static func loadCredentials() -> Credentials? {
        let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
        let keychain = Keychain(service: WooConstants.keychainServiceNameAppExtensions).accessibility(.afterFirstUnlock)
        guard let username = defaults?[.widgetExtensionUsername] as? String,
            let authToken = keychain[username],
            let siteAddress = defaults?[.widgetExtensionSiteAddress] as? String else {
            return nil
        }

        return Credentials(username: username, authToken: authToken, siteAddress: siteAddress)
    }

    /// Persists the Credentials's authToken in the keychain, and username in User Settings under the related App Groups.
    ///
    /// - Parameter credentials: the Authenticated Requests Credentials model
    /// - Parameter saveIfExist: if false, credentials are saved only if there are no existing credentials stored
    ///
    static func saveCredentials(_ credentials: Credentials, saveIfExist: Bool = true) {
        if saveIfExist == false {
            guard loadCredentials() == nil else {
                return
            }
        }
        let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
        defaults?[.widgetExtensionUsername] = credentials.username
        defaults?[.widgetExtensionSiteAddress] = credentials.siteAddress
        let keychain = Keychain(service: WooConstants.keychainServiceNameAppExtensions).accessibility(.afterFirstUnlock)
        keychain[credentials.username] = credentials.authToken
    }

    /// Nukes both, the AuthToken and Default Username, under the related App Groups.
    ///
    static func removeCredentials() {
        let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
        guard let username = defaults?[.widgetExtensionUsername] as? String else {
            return
        }

        let keychain = Keychain(service: WooConstants.keychainServiceNameAppExtensions).accessibility(.afterFirstUnlock)
        keychain[username] = nil
        defaults?[.widgetExtensionUsername] = nil
        defaults?[.widgetExtensionSiteAddress] = nil
    }
}

// WidgetExtensionService extension
// Save, Load and Remove the Site model used by Extensions of the Woo app, like the TodayStatsWidget
//
extension WidgetExtensionService {
    
    static func loadSite() -> Site? {
        let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
        
        if let savedSite = defaults?[.widgetExtensionSite] as? Data {
            let decoder = JSONDecoder()
            if let loadedSite = try? decoder.decode(Site.self, from: savedSite){
                return loadedSite
            }
        }
        return nil
    }
    
    static func saveSite(site: Site) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(site) {
            let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
            defaults?[.widgetExtensionSite] = encoded
        }
    }

    static func removeSite() {
        let defaults = UserDefaults(suiteName: WooConstants.wooAppsGroup)
        defaults?[.widgetExtensionSite] = nil
    }
}
