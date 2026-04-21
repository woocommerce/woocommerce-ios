import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct EditStoreListViewModelTests {
    // Given
    private let site1 = Site.fake().copy(siteID: 123)
    private let site2 = Site.fake().copy(siteID: 135)

    @Test func unhideStoreID_removes_store_from_hidden_list() {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults.saveHiddenStoreIDs([site1.siteID, site2.siteID])

        // When
        userDefaults.unhideStoreID(site1.siteID)

        // Then
        #expect(userDefaults.hiddenStoreIDs == [site2.siteID])
    }

    @Test func unhideStoreID_does_nothing_when_store_is_not_hidden() {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        userDefaults.saveHiddenStoreIDs([site2.siteID])

        // When
        userDefaults.unhideStoreID(site1.siteID)

        // Then
        #expect(userDefaults.hiddenStoreIDs == [site2.siteID])
    }

    @Test func hasChanges_returns_correct_values() {
        // Given
        let availableSites = [site1, site2]
        let displayedSites = [site1, site2]
        let viewModel = EditStoreListViewModel(availableSites: availableSites,
                                               displayedSites: displayedSites,
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.hasChanges == false)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.hasChanges == true)
    }

    @Test func isSelected_returns_correct_values() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.isSelected(site1) == true)
        #expect(viewModel.isSelected(site2) == true)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.isSelected(site1) == true)
        #expect(viewModel.isSelected(site2) == false)
    }

    @Test func isLastSelected_returns_correct_values() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // Then
        #expect(viewModel.isLastSelected(site1) == false)

        // When
        viewModel.selectedSites = Set([site1])

        // Then
        #expect(viewModel.isLastSelected(site1) == true)
    }

    @Test func toggleSelection_works_correctly() {
        // Given
        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == false)

        // When
        viewModel.toggleSelection(site1)

        // Then
        #expect(viewModel.selectedSites.contains(site1) == true)
    }

    @MainActor
    @Test func saveChanges_saves_hidden_store_ids_to_user_defaults_and_triggers_completion_if_there_is_no_deviceID() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false

        let notificationManager = MockPushNotificationsManager(mockedDeviceID: nil)

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(userDefaults.hiddenStoreIDs == [site1.siteID])
        #expect(completionTriggered == true)
    }

    @MainActor
    @Test func saveChanges_succeeds_when_updating_notification_settings_succeeds() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false

        let deviceID = "13435352"
        let notificationManager = MockPushNotificationsManager(mockedDeviceID: deviceID)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateNotificationSettings(_, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(userDefaults.hiddenStoreIDs == [site1.siteID])
        #expect(completionTriggered == true)
    }

    @MainActor
    @Test func saveChanges_fails_when_updating_notification_settings_fails() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false

        let deviceID = "13435352"
        let notificationManager = MockPushNotificationsManager(mockedDeviceID: deviceID)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateNotificationSettings(_, let onCompletion):
                let error = NSError(domain: "notification-settings-update-error", code: 501)
                onCompletion(.failure(error))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(userDefaults.hiddenStoreIDs == [])
        #expect(completionTriggered == false)
        #expect(viewModel.shouldShowErrorAlert == true)
    }

    // MARK: - Self-driven push notification unregistration

    @MainActor
    @Test func saveChanges_unregisters_hidden_sites_from_self_driven_push_notifications() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager(
            wooPushNotificationToken: "99",
            siteIDsRegisteredForWooPNs: [site1.siteID]
        )

        var unregisteredSiteIDs: [Int64] = []
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .unregisterFromSelfDrivenPushNotifications(siteID, tokenID, availableAsRESTRequest, onCompletion):
                #expect(tokenID == 99)
                // EditStoreListViewModel always unregisters non-current sites, so REST fallback
                // must be disabled to force the Jetpack tunnel to the correct site.
                #expect(availableAsRESTRequest == false)
                unregisteredSiteIDs.append(siteID)
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(unregisteredSiteIDs == [site1.siteID])
        #expect(notificationManager.unmarkedSiteIDs == [site1.siteID])
    }

    @MainActor
    @Test func saveChanges_skips_self_driven_unregistration_when_site_is_not_registered() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager(
            wooPushNotificationToken: "99",
            siteIDsRegisteredForWooPNs: [] // site1 is NOT registered
        )

        var unregisterActionDispatched = false
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case .unregisterFromSelfDrivenPushNotifications:
                unregisterActionDispatched = true
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(unregisterActionDispatched == false)
    }

    @MainActor
    @Test func saveChanges_skips_self_driven_unregistration_when_no_token() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager(
            wooPushNotificationToken: nil,
            siteIDsRegisteredForWooPNs: [site1.siteID]
        )

        var unregisterActionDispatched = false
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case .unregisterFromSelfDrivenPushNotifications:
                unregisterActionDispatched = true
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then
        #expect(unregisterActionDispatched == false)
    }

    @MainActor
    @Test func saveChanges_succeeds_even_when_self_driven_unregistration_fails() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false
        let notificationManager = MockPushNotificationsManager(
            wooPushNotificationToken: "99",
            siteIDsRegisteredForWooPNs: [site1.siteID]
        )

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .unregisterFromSelfDrivenPushNotifications(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "test", code: 500)))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then — save should still succeed despite self-driven PN unregistration failure
        #expect(userDefaults.hiddenStoreIDs == [site1.siteID])
        #expect(completionTriggered == true)
        #expect(notificationManager.unmarkedSiteIDs.isEmpty) // not unmarked because API failed
    }

    @MainActor
    @Test func saveChanges_unregisters_self_driven_PNs_even_without_WPCom_deviceID() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager(
            mockedDeviceID: nil, // no WPCom device ID
            wooPushNotificationToken: "99",
            siteIDsRegisteredForWooPNs: [site1.siteID]
        )

        var unregisteredSiteIDs: [Int64] = []
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .unregisterFromSelfDrivenPushNotifications(siteID, _, _, onCompletion):
                unregisteredSiteIDs.append(siteID)
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2],
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then — self-driven PN unregistration should still happen
        #expect(unregisteredSiteIDs == [site1.siteID])
        #expect(notificationManager.unmarkedSiteIDs == [site1.siteID])
    }

    // MARK: - Self-driven push notification registration for newly enabled sites

    @MainActor
    @Test func saveChanges_registers_newly_enabled_sites_for_self_driven_push_notifications() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager()

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site2], // site1 was hidden
                                               currentlySelectedSite: nil,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When — re-enable site1
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then — site1 should be registered for self-driven push notifications
        #expect(notificationManager.registeredSiteIDsForSelfDrivenPushNotifications == [site1.siteID])
    }

    @MainActor
    @Test func saveChanges_does_not_register_sites_that_were_already_enabled() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let notificationManager = MockPushNotificationsManager()

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2], // both were already enabled
                                               currentlySelectedSite: nil,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When — no changes, just save
        await viewModel.saveChanges()

        // Then — no registration attempts for already enabled sites
        #expect(notificationManager.registeredSiteIDsForSelfDrivenPushNotifications.isEmpty)
    }

    @MainActor
    @Test func saveChanges_succeeds_even_when_self_driven_registration_fails() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        var completionTriggered = false
        let notificationManager = MockPushNotificationsManager()
        notificationManager.registerSiteForSelfDrivenPushNotificationsResult = .failure(NSError(domain: "test", code: 500))

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site2], // site1 was hidden
                                               currentlySelectedSite: nil,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: { completionTriggered = true })

        // When — re-enable site1
        viewModel.toggleSelection(site1)
        await viewModel.saveChanges()

        // Then — save should still succeed despite self-driven PN registration failure
        #expect(completionTriggered == true)
        // Registration was attempted even though it failed
        #expect(notificationManager.registeredSiteIDsForSelfDrivenPushNotifications == [site1.siteID])
    }

    @MainActor
    @Test func saveChanges_disables_woo_registered_sites_in_wpcom_to_avoid_duplicates() async {
        // Given
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let deviceID = "13435352"
        let notificationManager = MockPushNotificationsManager(
            mockedDeviceID: deviceID,
            siteIDsRegisteredForWooPNs: [site1.siteID] // site1 is registered with Woo
        )

        var capturedEnabledSites: [Int64]?
        var capturedDisabledSites: [Int64]?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateNotificationSettings(let settings, let onCompletion):
                capturedEnabledSites = settings.blogs?.filter { $0.devices?.first?.newComment == true }.map { $0.blogID }
                capturedDisabledSites = settings.blogs?.filter { $0.devices?.first?.newComment == false }.map { $0.blogID }
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = EditStoreListViewModel(availableSites: [site1, site2],
                                               displayedSites: [site1, site2], // both displayed
                                               currentlySelectedSite: nil,
                                               stores: stores,
                                               pushNotificationManager: notificationManager,
                                               userDefaults: userDefaults,
                                               onCompletion: {})

        // When
        await viewModel.saveChanges()

        // Then — site1 (Woo-registered) should be disabled in WPCom, site2 should be enabled
        #expect(capturedEnabledSites == [site2.siteID])
        #expect(capturedDisabledSites == [site1.siteID])
    }
}
