@testable import WooCommerce
import Foundation

final class MockThemeInstaller: ThemeInstallerProtocol {
    var themeIDScheduledForInstall: String?
    var scheduleThemeInstallCalled = false
    func scheduleThemeInstall(themeID: String, siteID: Int64) {
        themeIDScheduledForInstall = themeID
    }

    var installPendingThemeCalled = false
    func installPendingTheme(siteID: Int64) async throws {
        installPendingThemeCalled = true
    }

    var installThemeCalledWithThemeID: String?
    var installThemeCalledForSiteID: Int64?
    var installThemeError: Error?
    var installThemeCalled = false
    func install(themeID: String, siteID: Int64) async throws {
        installThemeCalledWithThemeID = themeID
        installThemeCalledForSiteID = siteID
        installThemeCalled = true
        if let installThemeError {
            throw installThemeError
        }
    }
}
