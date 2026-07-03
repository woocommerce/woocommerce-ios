import Foundation
import Testing
@testable import WooCommerce
@testable import Yosemite

@Suite(.serialized, .timeLimit(.minutes(5)))
final class UpdateCrashReportingSettingUseCaseTests {

    private let userDefaults: UserDefaults
    private let suiteName: String

    init() throws {
        suiteName = "UpdateCrashReportingSettingUseCaseTests-\(UUID().uuidString)"
        userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
        SessionManager.removeTestingDatabase()
    }

    // MARK: - update(optOut:)

    @MainActor
    @Test func test_update_when_wpcom_account_opts_out_then_updates_remotely_and_locally() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        var receivedOptOut: Bool?
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, let optOut, let onCompletion):
                receivedOptOut = optOut
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        #expect(receivedOptOut == true)
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == false)
    }

    @MainActor
    @Test func test_update_when_remote_update_fails_then_throws_and_keeps_local_value() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, _, let onCompletion):
                onCompletion(.failure(NSError(domain: "Test", code: 0)))
            default:
                break
            }
        }

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        await #expect(throws: (any Error).self) {
            try await useCase.update(optOut: true)
        }

        // Then
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == true)
    }

    @MainActor
    @Test func test_update_when_non_wpcom_account_then_updates_locally_without_a_request() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        var dispatchedRemoteUpdate = false
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, _, let onCompletion):
                dispatchedRemoteUpdate = true
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        #expect(dispatchedRemoteUpdate == false)
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == false)
    }

    @MainActor
    @Test func test_update_when_setting_is_unchanged_then_does_not_fire_a_request() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        var dispatchedRemoteUpdate = false
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, _, let onCompletion):
                dispatchedRemoteUpdate = true
                onCompletion(.success(()))
            default:
                break
            }
        }
        CrashLoggingSettings.setDidOptIn(false, in: userDefaults)

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        try await useCase.update(optOut: true)

        // Then
        #expect(dispatchedRemoteUpdate == false)
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == false)
    }

    // MARK: - handleRemoteValue(_:userID:)

    @MainActor
    @Test(arguments: [true, false])
    func test_handleRemoteValue_when_a_choice_is_recorded_then_remote_value_wins_locally(remoteOptOut: Bool) throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        var dispatchedBackfill = false
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut:
                dispatchedBackfill = true
            default:
                break
            }
        }
        // Seed the opposite local value so the test fails if the remote value is ignored.
        CrashLoggingSettings.setDidOptIn(remoteOptOut, in: userDefaults)

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        useCase.handleRemoteValue(remoteOptOut, userID: 10)

        // Then
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == !remoteOptOut)
        #expect(dispatchedBackfill == false)
    }

    @MainActor
    @Test func test_handleRemoteValue_when_no_choice_is_recorded_then_backfills_the_local_value() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        var receivedOptOut: Bool?
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, let optOut, let onCompletion):
                receivedOptOut = optOut
                onCompletion(.success(()))
            default:
                break
            }
        }
        CrashLoggingSettings.setDidOptIn(false, in: userDefaults)

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        useCase.handleRemoteValue(nil, userID: 10)

        // Then
        #expect(receivedOptOut == true)
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == false)
    }

    @MainActor
    @Test func test_handleRemoteValue_when_no_choice_is_recorded_and_no_local_choice_then_backfills_the_default_opt_in() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, displayName: "Test Account"))
        var receivedOptOut: Bool?
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .updateCrashReportingOptOut(_, let optOut, let onCompletion):
                receivedOptOut = optOut
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        let useCase = UpdateCrashReportingSettingUseCase(stores: stores, userDefaults: userDefaults)
        useCase.handleRemoteValue(nil, userID: 10)

        // Then
        #expect(receivedOptOut == false)
        #expect(CrashLoggingSettings.didOptIn(in: userDefaults) == true)
    }
}
