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

    private let response = SelfHostedQRLoginExchangeResponse(userLogin: "shopkeeper",
                                                             siteURL: "https://shop.example",
                                                             applicationPassword: "ap-secret")

    // MARK: - Happy path

    @Test func complete_when_site_is_woo_and_user_is_eligible_then_returns_success_and_tracks_signedIn() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analytics = MockAnalyticsProvider()
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  analytics: analytics)

        // When
        let result = try await complete(service, response: response)

        // Then
        guard case .success = result else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.signedIn.rawValue))
        #expect(appPasswordUseCase.deletePasswordCallCount == 0)
    }

    // MARK: - Server-controlled site_url validation

    @Test func complete_when_response_siteURL_host_differs_from_scanned_then_revokes_ap_and_returns_siteAuthFailure() async throws {
        // Given — a malicious/compromised server returns a different host than the
        // one the merchant scanned and confirmed.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analytics = MockAnalyticsProvider()
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  analytics: analytics)
        let mismatchedResponse = makeResponse(siteURL: "https://evil.example")

        // When
        let result = try await complete(service, response: mismatchedResponse, scanned: "https://shop.example")

        // Then — never authenticate against the server's claimed host; revoke the
        // already-minted AP and surface a sign-in failure.
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .siteAuthFailure)
        #expect(error.phase == .postExchange)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
        #expect(analytics.receivedEvents.contains(WooAnalyticsStat.signedIn.rawValue) == false)
    }

    @Test func complete_when_response_siteURL_downgrades_scheme_to_http_then_revokes_ap_and_returns_siteAuthFailure() async throws {
        // Given — scanned URL was https (release rule), server tries to bind the
        // credentials to a cleartext http endpoint.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase)
        let downgradedResponse = makeResponse(siteURL: "http://shop.example")

        // When
        let result = try await complete(service, response: downgradedResponse, scanned: "https://shop.example")

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .siteAuthFailure)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_response_siteURL_matches_host_and_scheme_then_authenticates_against_response_url() async throws {
        // Given — same host and scheme but a canonical subdirectory path; the
        // response value should be used verbatim so the install path is preserved.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        var capturedSiteAddress: String?
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  onSiteAddress: { capturedSiteAddress = $0 })
        let canonicalResponse = makeResponse(siteURL: "https://shop.example/blog")

        // When
        let result = try await complete(service, response: canonicalResponse, scanned: "https://shop.example")

        // Then
        guard case .success = result else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(capturedSiteAddress == "https://shop.example/blog")
    }

    // MARK: - Failure paths

    @Test func complete_when_fetchSiteInfo_fails_then_revokes_ap_and_returns_siteAuthFailure() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analytics = MockAnalyticsProvider()
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .failure(NSError(domain: "test", code: 0)))
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase,
                                  analytics: analytics)

        // When
        let result = try await complete(service, response: response)

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

    @Test func complete_when_site_is_not_woo_then_revokes_ap_and_returns_notAWooSite() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeNonWooSite()))
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = try await complete(service, response: response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .notAWooSite)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_user_role_insufficient_then_revokes_ap_and_returns_userNotEligible() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let info = StorageEligibilityErrorInfo(name: "shopkeeper", roles: ["author"])
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .failure(.insufficientRole(info: info))),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = try await complete(service, response: response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .userNotEligible)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_role_check_errors_then_returns_siteAuthFailure() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        stubFetchSiteInfo(stores: stores, result: .success(makeWooSite()))
        let underlying = NSError(domain: "test", code: 42)
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .failure(.unknown(error: underlying))),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = try await complete(service, response: response)

        // Then
        guard case let .failure(error) = result else {
            Issue.record("Expected .failure, got \(result)")
            return
        }
        #expect(error.kind == .siteAuthFailure)
        #expect(appPasswordUseCase.deletePasswordCallCount == 1)
    }

    @Test func complete_when_revoke_itself_fails_then_still_surfaces_original_error() async throws {
        // Given — revoke throws, we should still bubble up the original failure.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stubFetchSiteInfo(stores: stores, result: .success(makeNonWooSite()))
        let appPasswordUseCase = MockApplicationPasswordUseCase()
        appPasswordUseCase.deletePasswordError = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        let service = makeService(stores: stores,
                                  roleEligibility: StubRoleEligibilityUseCase(result: .success(())),
                                  appPasswordUseCase: appPasswordUseCase)

        // When
        let result = try await complete(service, response: response)

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

    /// Calls `complete` with a scanned URL, defaulting to one that matches the
    /// default `response.siteURL` so the validation step passes for the existing
    /// cases. Uses `#require` rather than force-unwrap per project conventions.
    func complete(_ service: QRLoginPostExchangeService,
                  response: SelfHostedQRLoginExchangeResponse,
                  scanned: String = "https://shop.example") async throws -> Result<Void, QRLoginUserFacingError> {
        let scannedURL = try #require(URL(string: scanned))
        return await service.complete(response, scannedSiteURL: scannedURL)
    }

    func makeService(stores: MockStoresManager,
                     roleEligibility: RoleEligibilityUseCaseProtocol,
                     appPasswordUseCase: MockApplicationPasswordUseCase,
                     analytics: MockAnalyticsProvider = MockAnalyticsProvider(),
                     onSiteAddress: ((String) -> Void)? = nil) -> QRLoginPostExchangeService {
        QRLoginPostExchangeService(
            stores: stores,
            roleEligibilityUseCase: roleEligibility,
            applicationPasswordUseCaseFactory: { _, siteAddress in
                onSiteAddress?(siteAddress)
                return appPasswordUseCase
            },
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

    func makeResponse(siteURL: String) -> SelfHostedQRLoginExchangeResponse {
        SelfHostedQRLoginExchangeResponse(userLogin: "shopkeeper",
                                          siteURL: siteURL,
                                          applicationPassword: "ap-secret")
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

private final class StubRoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {
    private let result: Result<Void, RoleEligibilityError>

    init(result: Result<Void, RoleEligibilityError>) {
        self.result = result
    }

    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void) {
        completion(result)
    }
}
