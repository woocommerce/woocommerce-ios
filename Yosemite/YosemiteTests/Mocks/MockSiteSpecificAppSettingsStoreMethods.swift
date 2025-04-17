@testable import Yosemite
import Storage

final class MockSiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol {
    var getStoreSettingsCalled = false
    var setStoreSettingsCalled = false
    var resetStoreSettingsCalled = false
    var setStoreIDCalled = false
    var getStoreIDCalled = false
    var spySetStoreID: String? = nil
    var spySetStoreIDSiteID: Int64? = nil

    var spyGetStoreID: String? = nil
    var spyGetStoreIDSiteID: Int64? = nil

    var mockStoreSettings = GeneralStoreSettings()
    var mockStoreID: String?
    var mockError: Error?

    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        getStoreSettingsCalled = true
        return mockStoreSettings
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)?) {
        setStoreSettingsCalled = true
        if let error = mockError {
            onCompletion?(.failure(error))
        } else {
            onCompletion?(.success(()))
        }
    }

    func resetStoreSettings() {
        resetStoreSettingsCalled = true
    }

    func setStoreID(siteID: Int64, id: String?) {
        setStoreIDCalled = true
        mockStoreID = id
    }

    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        getStoreIDCalled = true
        onCompletion(mockStoreID)
    }
}
