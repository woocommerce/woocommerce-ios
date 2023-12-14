@testable import WooCommerce
import Foundation

final class MockThemeInstaller: ThemeInstaller {
    var themeIDScheduledForInstall: String?
    var scheduleThemeInstallCalled = false
    func scheduleThemeInstall(themeID: String, siteID: Int64) {
        themeIDScheduledForInstall = themeID
    }

    var installPendingThemeCalledForSiteID: Int64?
    var installPendingThemeCalled = false
    func installPendingTheme(siteID: Int64) async throws {
        installPendingThemeCalled = true
        installPendingThemeCalledForSiteID = siteID
    }

    func install(themeID: String, siteID: Int64) async throws {
        // no-op
    }
}
