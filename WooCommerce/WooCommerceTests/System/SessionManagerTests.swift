import XCTest
@testable import WooCommerce
import Yosemite
import KeychainAccess
@testable import Networking
import Storage

/// SessionManager Unit Tests
///
final class SessionManagerTests: XCTestCase {

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username", password: .init("password"), uuid: "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e")

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var manager = SessionManager(defaults: Settings.defaults, keychainServiceName: Settings.keychainServiceName)

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        manager.defaultCredentials = nil
    }

    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPCOM() {
        // Given
        manager.defaultCredentials = Settings.wpcomCredentials

        guard case let .wpcom(username, authToken, siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.wpcom(username: username, authToken: authToken, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wpcomCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPOrg() {
        // Given
        manager.defaultCredentials = Settings.wporgCredentials

        guard case let .wporg(username: username, password: password, siteAddress: siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.wporg(username: username, password: password, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wporgCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func test_default_credentials_are_properly_persisted_for_application_password() {
        // Given
        manager.defaultCredentials = Settings.applicationPasswordCredentials

        guard case let .applicationPassword(username, password, siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.applicationPassword(username: username, password: password, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.applicationPasswordCredentials)
    }

    /// Verifies that application password is deleted upon calling `deleteApplicationPassword`
    ///
    func test_deleteApplicationPassword_deletes_password_from_keychain() {
        // Given
        manager.defaultCredentials = Settings.wporgCredentials
        let storage = ApplicationPasswordStorage(keychain: Keychain(service: Settings.keychainServiceName))

        // When
        storage.saveApplicationPassword(applicationPassword)

        // Then
        XCTAssertNotNil(storage.applicationPassword)

        // When
        manager.deleteApplicationPassword()

        // Then
        waitUntil {
            storage.applicationPassword == nil
        }
    }

    /// Verifies that application password is deleted upon reset
    ///
    func test_application_password_is_deleted_upon_reset() {
        // Given
        manager.defaultCredentials = Settings.wporgCredentials
        let storage = ApplicationPasswordStorage(keychain: Keychain(service: Settings.keychainServiceName))

        // When
        storage.saveApplicationPassword(applicationPassword)

        // Then
        XCTAssertNotNil(storage.applicationPassword)

        // When
        manager.reset()

        // Then
        waitUntil {
            storage.applicationPassword == nil
        }
    }

    /// Verifies that `storePhoneNumber` is set to `nil` upon reset
    ///
    func test_storePhoneNumber_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.storePhoneNumber] = "0123456789"

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.storePhoneNumber] as? String), "0123456789")

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.storePhoneNumber])
    }

    /// Verifies that `completedAllStoreOnboardingTasks` is set to `nil` upon reset
    ///
    func test_completedAllStoreOnboardingTasks_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    /// Verifies that `usedProductDescriptionAI` is set to `nil` upon reset
    ///
    func test_usedProductDescriptionAI_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.usedProductDescriptionAI] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.usedProductDescriptionAI] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.usedProductDescriptionAI])
    }

    /// Verifies that `hasDismissedWriteWithAITooltip` is set to `nil` upon reset
    ///
    func test_hasDismissedWriteWithAITooltip_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip])
    }

    /// Verifies that `numberOfTimesWriteWithAITooltipIsShown` is set to `nil` upon reset
    ///
    func test_numberOfTimesWriteWithAITooltipIsShown_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] = 3

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] as? Int), 3)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown])
    }

    /// Verifies that `storeProfilerAnswers` is set to `nil` upon reset
    ///
    func test_storeProfilerAnswers_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        let encodedObject = try JSONEncoder().encode(["test": "test"])
        defaults[UserDefaults.Key.storeProfilerAnswers] = ["123": encodedObject]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.storeProfilerAnswers] as? [String: Data]), ["123": encodedObject])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.storeProfilerAnswers])
    }

    /// Verifies that `aiPromptTone` is set to `nil` upon reset
    ///
    func test_aiPromptTone_is_set_to_nil_upon_reset() throws {
        // Given
        let siteID: Int64 = 123
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.convincing.rawValue]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .convincing)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.aiPromptTone])
    }

    /// Verifies that `numberOfTimesProductCreationAISurveySuggested` is set to `nil` upon reset
    ///
    func test_numberOfTimesProductCreationAISurveySuggested_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.numberOfTimesProductCreationAISurveySuggested] = 2

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.numberOfTimesProductCreationAISurveySuggested] as? Int), 2)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.numberOfTimesProductCreationAISurveySuggested])
    }

    /// Verifies that `didStartProductCreationAISurvey` is set to `nil` upon reset
    ///
    func test_didStartProductCreationAISurvey_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.didStartProductCreationAISurvey] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.didStartProductCreationAISurvey] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.didStartProductCreationAISurvey])
    }

    /// Verifies that `themesPendingInstall` is set to `nil` upon reset
    ///
    func test_themesPendingInstall_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.themesPendingInstall] = ["123": "321"]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.themesPendingInstall] as? [String: String]), ["123": "321"])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.themesPendingInstall])
    }

    /// Verifies that `siteIDPendingStoreSwitch` is set to `nil` upon reset
    ///
    func test_siteIDPendingStoreSwitch_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)
        let siteID: Int64 = 123

        // When
        defaults[.siteIDPendingStoreSwitch] = siteID

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.siteIDPendingStoreSwitch] as? Int64), siteID)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.siteIDPendingStoreSwitch])
    }

    /// Verifies that `expectedStoreNamePendingStoreSwitch` is set to `nil` upon reset
    ///
    func test_expectedStoreNamePendingStoreSwitch_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)
        let storeName = "My Woo Store"

        // When
        defaults[.expectedStoreNamePendingStoreSwitch] = storeName

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.expectedStoreNamePendingStoreSwitch] as? String), storeName)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.expectedStoreNamePendingStoreSwitch])
    }

    /// Verifies that image cache is cleared upon reset
    ///
    func test_image_cache_is_cleared_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockCache = MockImageCache(name: "Testing")
        let sut = SessionManager(defaults: defaults,
                                 keychainServiceName: Settings.keychainServiceName,
                                 imageCache: mockCache)

        // When
        sut.reset()

        // Then
        XCTAssertTrue(mockCache.clearCacheCalled)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.defaultCredentials = Settings.wpcomCredentials
        manager.defaultCredentials = nil

        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.defaultCredentials = Settings.wpcomCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wpcomCredentials)

        manager.defaultCredentials = Settings.wporgCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wporgCredentials)
    }

    /// Verifies that WPCOM credentials are returned for already installed and logged in versions which don't have type stored in user defaults
    ///
    func test_already_installed_version_without_authentication_type_saved_returns_WPCOM_credentials() throws {
        // Given
        let uuid = UUID().uuidString

        // Prepare user defaults
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[UserDefaults.Key.defaultUsername] = "lalala"
        defaults[UserDefaults.Key.defaultSiteAddress] = "https://example.com"

        // Prepare keychain
        let keychainServiceName = uuid
        Keychain(service: keychainServiceName)["lalala"] = "1234"

        // When

        // Check that credential type isn't available
        XCTAssertNil(defaults[UserDefaults.Key.defaultCredentialsType])

        let sut = SessionManager(defaults: defaults, keychainServiceName: keychainServiceName)

        // Then
        XCTAssertEqual(sut.defaultCredentials, Settings.wpcomCredentials)
    }

    func test_core_data_reset_clears_timestamps_stores() throws {

        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // Preload info
        defaults[UserDefaults.Key.latestBackgroundOrderSyncDate] = Date.now
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                DashboardTimestampStore.saveTimestamp(Date.now, for: card, at: range, store: defaults)
            }
        }

        // When
        let sut = SessionManager(defaults: defaults, keychainServiceName: uuid)
        NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: nil)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.latestBackgroundOrderSyncDate])
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                XCTAssertNil(DashboardTimestampStore.loadTimestamp(for: card, at: range, store: defaults))
            }
        }
    }
}

// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let wpcomCredentials = Credentials.wpcom(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let wporgCredentials = Credentials.wporg(username: "yayaya", password: "5678", siteAddress: "https://wordpress.com")
    static let applicationPasswordCredentials = Credentials.applicationPassword(username: "username", password: "password", siteAddress: "siteAddress")
}
