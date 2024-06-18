import Yosemite
import enum Networking.InstallThemeError
import protocol WooFoundation.Analytics

protocol ThemeInstaller {
    func install(themeID: String, siteID: Int64) async throws

    func scheduleThemeInstall(themeID: String, siteID: Int64)

    func installPendingThemeIfNeeded(siteID: Int64) async throws
}

/// Helper to install and activate theme
///
struct DefaultThemeInstaller: ThemeInstaller {
    private let userDefaults: UserDefaults
    private let stores: StoresManager
    private let analytics: Analytics

    init(stores: StoresManager = ServiceLocator.stores,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.userDefaults = userDefaults
        self.analytics = analytics
    }

    /// Installs and activates the theme
    /// - Parameters:
    ///   - themeID: ID of the theme to be installed and activated
    ///   - siteID: site ID to install and activate the theme
    func install(themeID: String, siteID: Int64) async throws {
        try await installAndActivateTheme(themeID: themeID, siteID: siteID)
    }

    /// Schedules the given themeID for installation and activation
    /// - Parameters:
    ///   - themeID: ID of the theme to be installed and activated
    ///   - siteID: site ID to install and activate the theme
    func scheduleThemeInstall(themeID: String, siteID: Int64) {
        userDefaults.setPendingThemeID(themeID: themeID, for: siteID)
    }

    /// Installs any pending theme for the given site ID
    /// - Parameter siteID: site ID to install and activate the theme
    func installPendingThemeIfNeeded(siteID: Int64) async throws {
        guard let themeID = userDefaults.pendingThemeID(for: siteID) else {
            return DDLogInfo("No pending theme installation.")
        }

        DDLogInfo("Attempt to perform pending theme installation. Theme ID: \(themeID), Site ID : \(siteID)")
        try await installAndActivateTheme(themeID: themeID, siteID: siteID)
        userDefaults.removePendingThemeID(for: siteID)
    }
}

private extension DefaultThemeInstaller {
    func installAndActivateTheme(themeID: String, siteID: Int64) async throws {
        do {
            try await installTheme(themeID: themeID, siteID: siteID)
            try await activateTheme(themeID: themeID, siteID: siteID)
            analytics.track(event: .Themes.themeInstallationCompleted(themeID: themeID))
        } catch {
            DDLogError("⛔️ Error installing theme: \(error)")
            analytics.track(event: .Themes.themeInstallationFailed(themeID: themeID, error: error))
            throw error
        }
    }

    @MainActor
    func installTheme(themeID: String,
                      siteID: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WordPressThemeAction.installTheme(themeID: themeID, siteID: siteID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    if error as? InstallThemeError == .themeAlreadyInstalled {
                        DDLogInfo("Theme already installed.")
                        continuation.resume()
                    } else {
                        DDLogError("⛔️ Theme installation failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            })
        }
    }

    @MainActor
    func activateTheme(themeID: String,
                       siteID: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WordPressThemeAction.activateTheme(themeID: themeID, siteID: siteID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    DDLogError("⛔️ Theme activation failed: \(error)")
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

// MARK: - DefaultThemeInstaller helpers
//
private extension UserDefaults {
    /// Returns theme ID to be installed for the store
    ///
    func pendingThemeID(for siteID: Int64) -> String? {
        let themesPendingInstall = self[.themesPendingInstall] as? [String: String]
        let idAsString = "\(siteID)"
        return themesPendingInstall?[idAsString]
    }

    /// Saves theme ID for installation
    ///
    func setPendingThemeID(themeID: String,
                           for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var themesPendingInstallDictionary = self[.themesPendingInstall] as? [String: String] {
            themesPendingInstallDictionary[idAsString] = themeID
            self[.themesPendingInstall] = themesPendingInstallDictionary
        } else {
            self[.themesPendingInstall] = [idAsString: themeID]
        }
    }

    func removePendingThemeID(for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var themesPendingInstallDictionary = self[.themesPendingInstall] as? [String: String] {
            themesPendingInstallDictionary[idAsString] = nil
            self[.themesPendingInstall] = themesPendingInstallDictionary
        }
    }
}
