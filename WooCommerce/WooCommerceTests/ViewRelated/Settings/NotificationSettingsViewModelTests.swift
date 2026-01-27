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
    @Test func sites_excludes_sites_registered_for_woo_pn() async {
        // Given
        let storageManager = MockStorageManager()
        let testSite1 = Site.fake().copy(siteID: 123, name: "Miffy", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 243, name: "Matsui", isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)

        let pushNotificationManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [243])
        let viewModel = NotificationSettingsViewModel(storageManager: storageManager,
                                                      pushNotificationManager: pushNotificationManager)

        // Then
        #expect(viewModel.sites == [testSite1])
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

    @Test func retrieveNotificationSettings_does_not_return_error_when_device_id_is_unavailable() async throws {
        // Given
        let pushNotificationManager = MockPushNotificationsManager()
        let viewModel = NotificationSettingsViewModel(pushNotificationManager: pushNotificationManager)

        // When
        await viewModel.retrieveNotificationSettings()

        // Then
        #expect(viewModel.loadingSiteSettingsFailed == false)
        #expect(viewModel.siteSettings == nil)
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
        #expect(viewModel.siteSettings == expectedSettings)
    }

    @MainActor
    @Test func retrieveNotificationSettings_returns_error_when_fails() async throws {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        // When
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
        #expect(viewModel.loadingSiteSettingsFailed == true)
    }

    @MainActor
    @Test func loadSettings_returns_correct_settings_for_given_site() async {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: true, storeOrder: true)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            default:
                break
            }
        }

        // When
        await viewModel.retrieveNotificationSettings()
        let settings = viewModel.loadSettings(for: Site.fake().copy(siteID: 136))

        // Then
        #expect(settings == expectedSettings.blogs[1].devices[0])
    }

    @MainActor
    @Test func updateSettings_updates_current_settings_correctly() async {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: true, storeOrder: true)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            default:
                break
            }
        }

        // When
        await viewModel.retrieveNotificationSettings()
        viewModel.updateSettings(siteID: 136, ordersNotificationsEnabled: false, productReviewsNotificationsEnabled: false)

        // Then
        let updatedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: false, storeOrder: false)])
        ])
        #expect(viewModel.siteSettings == updatedSettings)
    }

    @MainActor
    @Test func saveSettings_updates_notice_when_succeeds() async {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)
        #expect(viewModel.notice == nil)

        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: true, storeOrder: true)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            case let .updateNotificationSettings(_, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        await viewModel.retrieveNotificationSettings()
        viewModel.updateSettings(siteID: 136, ordersNotificationsEnabled: false, productReviewsNotificationsEnabled: false)
        await viewModel.saveSettings()

        // Then
        #expect(viewModel.notice != nil)
    }

    @MainActor
    @Test func saveSettings_throws_error_when_fails() async {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)

        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: true, storeOrder: true)])
        ])
        let expectedError = NSError(domain: "Test", code: 400)
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            case let .updateNotificationSettings(_, onCompletion):
                onCompletion(.failure(expectedError))
            default:
                break
            }
        }

        await viewModel.retrieveNotificationSettings()
        viewModel.updateSettings(siteID: 136, ordersNotificationsEnabled: false, productReviewsNotificationsEnabled: false)

        // When
        await viewModel.saveSettings()

        // Then
        #expect(viewModel.savingSiteSettingsFailed == true)
    }

    @MainActor
    @Test func hasSiteSettingsChanges_returns_correctly() async {
        // Given
        let pushNotificationManager = MockPushNotificationsManager(mockedDeviceID: "132")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = NotificationSettingsViewModel(stores: stores, pushNotificationManager: pushNotificationManager)
        #expect(viewModel.hasSiteSettingsChanges == false)

        let expectedSettings = NotificationSettings(blogs: [
            .init(blogID: 134, devices: [.init(deviceID: 132, newComment: true, storeOrder: false)]),
            .init(blogID: 136, devices: [.init(deviceID: 132, newComment: true, storeOrder: true)])
        ])
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .loadNotificationSettings(_, onCompletion):
                onCompletion(.success(expectedSettings))
            case let .updateNotificationSettings(_, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        await viewModel.retrieveNotificationSettings()
        viewModel.updateSettings(siteID: 136, ordersNotificationsEnabled: false, productReviewsNotificationsEnabled: false)

        // Then
        #expect(viewModel.hasSiteSettingsChanges == true)

        // When
        await viewModel.saveSettings()
        #expect(viewModel.hasSiteSettingsChanges == false)
    }
}
