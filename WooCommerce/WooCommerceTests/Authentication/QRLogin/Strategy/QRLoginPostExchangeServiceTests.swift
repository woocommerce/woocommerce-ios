import Foundation
import Networking
import Testing
import Yosemite
import struct NetworkingCore.ApplicationPassword
import protocol NetworkingCore.ApplicationPasswordUseCase
import enum NetworkingCore.ApplicationPasswordUseCaseError
import struct NetworkingCore.Secret
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct QRLoginPostExchangeServiceTests {

    private let response = QRLoginSelfHostedExchangeResponse(userLogin: "shopkeeper",
                                                             siteURL: "https://shop.example",
                                                             applicationPassword: "ap-secret")

    // MARK: - Happy path

    @Test func complete_when_site_is_woo_and_user_is_eligible_then_returns_success_and_tracks_signedIn() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analytics = MockAnalyticsProvider()
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  analytics: analytics)

        // When
        let result = await service.complete(response)

        // Then
        guard case .success = result else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.signedIn.rawValue))
        #expect(appPasswordUseCase.deletePasswordCallCount == 0)
    }

    // MARK: - Failure paths (spec §5.1.4)

    @Test func complete_when_fetchSiteInfo_fails_then_revokes_ap_and_returns_siteAuthFailure() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analytics = MockAnalyticsProvider()
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .failure(NSError(domain: "test", code: 0)))
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  analytics: analytics)

        // When
        let result = await service.complete(response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .siteAuthFailure)
        #expect(error.phase == .postExchange)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
        #expect(appPasswordUseCase.deletePasswordLocally == true)
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.signedIn.rawValue) == false)
    }

    @Test func complete_when_site_is_not_woo_then_revokes_ap_and_returns_notAWooSite() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeNonWooSite()))
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = await service.complete(response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .notAWooSite)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_user_role_insufficient_then_revokes_ap_and_returns_userNotEligible() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let info = StorageEligibilityErrorInfo(name: "shopkeeper", roles: ["author"])
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .failure(.insufficientRole(info: info))),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = await service.complete(response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .userNotEligible)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_role_check_errors_then_returns_siteAuthFailure() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let underlying = NSError(domain: "test", code: 42)
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .failure(.unknown(error: underlying))),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = await service.complete(response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .siteAuthFailure)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_revoke_itself_fails_then_still_surfaces_original_error() async {
        // Given — revoke throws, we should still bubble up the original failure.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stubFetchSiteInfo(stores: stores, result: .success(makeNonWooSite()))
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        appPasswordUseCase.deletePasswordError = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        let service = makeService(stores: stores,
                                  roleEligibility: MockRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = await service.complete(response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .notAWooSite) // original error preserved
        #expect(appPasswordUseCase.deletePasswordCallCount == 1) // revoke was attempted
    }
}

// MARK: - Helpers

@MainActor
private extension QRLoginPostExchangeServiceTests {

    func makeService(stores: MockStoresManager,
                     roleEligibility: RoleEligibilityUseCaseProtocol,
                     appPasswordUseCase: MockApplicationPasswordUseCase,
                     analytics: MockAnalyticsProvider = MockAnalyticsProvider()) -> QRLoginPostExchangeService {
        QRLoginPostExchangeService(
            stores: stores,
            roleEligibilityUseCase: roleEligibility,
            applicationPasswordUseCaseFactory: { _, _ in appPasswordUseCase },
            analytics: WooAnalytics(analyticsProvider: analytics)
        )
    }

    func stubFetchSiteInfo(stores: MockStoresManager, result: Result<Site, Error>) {
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchSiteInfo(_, completion) = action {
                completion(result)
            }
        }
    }

    func makeWooSite() -> Site {
        Site.fake().copy(siteID: 99, name: "Shop", isWooCommerceActive: true)
    }

    func makeNonWooSite() -> Site {
        Site.fake().copy(siteID: 99, name: "Plain WP", isWooCommerceActive: false)
    }
}

// MARK: - Mocks

@MainActor
private final class MockApplicationPasswordUseCase: ApplicationPasswordUseCase {
    let applicationPassword: ApplicationPassword? = ApplicationPassword(
        wpOrgUsername: "u",
        password: Secret("p"),
        uuid: "uuid"
    )
    let canRegenerateApplicationPassword: Bool = false

    var deletePasswordCallCount = 0
    var deletePasswordLocally = false
    var deletePasswordError: Error?

    func generateNewPassword() async throws -> ApplicationPassword {
        throw ApplicationPasswordUseCaseError.notSupported
    }

    func deletePassword(locally: Bool) async throws {
        deletePasswordCallCount += 1
        deletePasswordLocally = locally
        if let deletePasswordError {
            throw deletePasswordError
        }
    }
}

private final class MockRoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {
    private let result: Result<Void, RoleEligibilityError>

    init(result: Result<Void, RoleEligibilityError>) {
        self.result = result
    }

    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void) {
        completion(result)
    }
}
