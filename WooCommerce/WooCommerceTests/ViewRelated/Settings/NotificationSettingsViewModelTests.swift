import UserNotifications
import Testing
import Yosemite
@testable import WooCommerce

struct NotificationSettingsViewModelTests {

    @Test(arguments: [
        UNAuthorizationStatus.notDetermined,
        UNAuthorizationStatus.denied,
        UNAuthorizationStatus.provisional,
        UNAuthorizationStatus.ephemeral
    ])
    func notificationsEnabled_is_false_notification_permission_is_not_authorized(authorizationStatus: UNAuthorizationStatus) async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = authorizationStatus
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // When
        await viewModel.checkNotificationPermission()

        // Then
        #expect(viewModel.notificationsEnabled == false)
    }

    @Test func notificationsEnabled_is_true_notification_permission_is_authorized() async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .authorized
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // When
        await viewModel.checkNotificationPermission()

        // Then
        #expect(viewModel.notificationsEnabled == true)
    }

    @MainActor
    @Test func sites_include_storage_data_if_syncing_fails() async {
        // Given
        let storageManager = MockStorageManager()
        let testSite1 = Site.fake().copy(siteID: 123, name: "Miffy", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 243, name: "Matsui", isWooCommerceActive: true)
        let testSite3 = Site.fake().copy(siteID: 233, name: "Kitty", isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        storageManager.insertSampleSite(readOnlySite: testSite3)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let notificationCenter = MockUserNotificationsCenterAdapter()

        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter,
                                                      stores: stores,
                                                      storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.failure(NSError(domain: "test", code: 500)))
            default:
                break
            }
        }
        await viewModel.synchronizeSites()

        // Then
        #expect(viewModel.sites == [testSite2, testSite1])
    }

    @MainActor
    @Test func sites_is_updated_when_syncing_succeeds() async throws {
        // Given
        let storageManager = MockStorageManager()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let notificationCenter = MockUserNotificationsCenterAdapter()

        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter,
                                                      stores: stores,
                                                      storageManager: storageManager)

        // When
        let testSite4 = Site.fake().copy(siteID: 11, name: "Lala", isWooCommerceActive: true)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                storageManager.insertSampleSite(readOnlySite: testSite4)
                onCompletion(.success(false))
            default:
                break
            }
        }
        await viewModel.synchronizeSites()
        try await Task.sleep(nanoseconds: 200) // workaround to wait for update

        // Then
        #expect(viewModel.sites == [testSite4])
    }

    @Test func retrieveNotificationSettings_returns_error_when_device_id_is_unavailable() async throws {
        // Given
        let pushNotificationManager = MockPushNotificationsManager()
        let viewModel = NotificationSettingsViewModel(pushNotificationManager: pushNotificationManager)

        // When
        await viewModel.retrieveNotificationSettings()

        // Then
        let error = try #require(viewModel.loadingSiteSettingsError)
        #expect(error == .deviceNotAvailable)
    }

    @MainActor
    @Test func retrieveNotificationSettings_updates_settings_when_succeeds() async throws {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        // When
        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            default:
                break
            }
        }
        await viewModel.retrieveNotificationSettings()

        // Then
        let settings = try #require(viewModel.siteSettings)
        #expect(settings == expectedSettings)
    }

    @MainActor
    @Test func retrieveNotificationSettings_updates_error_when_fails() async throws {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        // When
        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.failure(NSError(domain: "Test", code: 400)))
            default:
                break
            }
        }
        await viewModel.retrieveNotificationSettings()

        // Then
        let error = try #require(viewModel.loadingSiteSettingsError)
        #expect(error == .loadingFailed)
    }
}
