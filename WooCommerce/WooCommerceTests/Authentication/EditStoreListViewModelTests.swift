import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct EditStoreListViewModelTests {
    // Given
    private let site1 = Site.fake().copy(siteID: 123)
    private let site2 = Site.fake().copy(siteID: 135)

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
}
