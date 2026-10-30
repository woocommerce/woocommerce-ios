import Foundation
import Testing
import YosemiteTestHelpers
import protocol Alamofire.URLRequestConvertible
@testable import Yosemite
@testable import Networking
@testable import NetworkingCore
@testable import Storage

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct PaymentDiagnosticReadResponseTests {
    enum Endpoint: CaseIterable, Sendable {
        case wcPay, stripe, generalSettings, systemStatus

        func action(siteID: Int64, completion: @escaping @Sendable (Result<Void, Error>) -> Void) -> Action {
            switch self {
            case .wcPay, .stripe:
                return CardPresentPaymentAction.fetchPaymentGatewayAccount(siteID: siteID, gateway: self == .wcPay ? .wcPay : .stripe) {
                    completion($0.map { _ in () })
                }
            case .generalSettings:
                return SettingAction.retrieveGeneralSiteSettings(siteID: siteID) { completion($0.map { _ in () }) }
            case .systemStatus:
                return SystemStatusAction.fetchSystemStatusReport(siteID: siteID, detectUnexpectedResponses: true) {
                    completion($0.map { _ in () })
                }
            }
        }

        @MainActor
        func store(dispatcher: Dispatcher, storage: MockStorageManager, network: MockNetwork) -> Store {
            switch self {
            case .wcPay, .stripe:
                return CardPresentPaymentStore(dispatcher: dispatcher, storageManager: storage, network: network,
                                               cardReaderService: MockCardReaderService(), cardReaderConfigProvider: MockCommonReaderConfigProviding())
            case .generalSettings:
                return SettingStore(dispatcher: dispatcher, storageManager: storage, network: network)
            case .systemStatus:
                return SystemStatusStore(dispatcher: dispatcher, storageManager: storage, network: network)
            }
        }

        func fetchWithDefaultPolicy(network: MockNetwork) async -> Result<Void, Error> {
            let remote: Remote
            let result: Result<Void, Error>
            switch self {
            case .wcPay:
                let target = WCPayRemote(network: network)
                remote = target
                result = await withCheckedContinuation { continuation in
                    target.loadAccount(for: 123) { continuation.resume(returning: $0.map { _ in () }) }
                }
            case .stripe:
                let target = StripeRemote(network: network)
                remote = target
                result = await withCheckedContinuation { continuation in
                    target.loadAccount(for: 123) { continuation.resume(returning: $0.map { _ in () }) }
                }
            case .generalSettings:
                let target = SiteSettingsRemote(network: network)
                remote = target
                result = await withCheckedContinuation { continuation in
                    target.loadGeneralSettings(for: 123) { settings, error in
                        if let error {
                            continuation.resume(returning: .failure(error))
                        } else if settings != nil {
                            continuation.resume(returning: .success(()))
                        } else {
                            continuation.resume(returning: .failure(SettingError.parseError))
                        }
                    }
                }
            case .systemStatus:
                let target = SystemStatusRemote(network: network)
                remote = target
                result = await withCheckedContinuation { continuation in
                    target.fetchSystemStatusReport(for: 123) { continuation.resume(returning: $0.map { _ in () }) }
                }
            }
            withExtendedLifetime(remote) {}
            return result
        }
    }

    enum Response: CaseIterable, Sendable {
        case directJSON503, tunnelJSON503, malformedSchema
    }

    @Test(arguments: Endpoint.allCases, Response.allCases)
    func test_diagnostic_read_when_response_fails_then_preserves_status_and_does_not_write_cache(endpoint: Endpoint, response: Response) async throws {
        // Given
        let dispatcher = Dispatcher()
        let storage = MockStorageManager()
        let network = MockPaymentDiagnosticResponseNetwork(response: response, expectsDetection: true)
        let store = endpoint.store(dispatcher: dispatcher, storage: storage, network: network)
        let settingsActions = MockActionsProcessor()
        dispatcher.register(processor: settingsActions, for: AppSettingsAction.self)

        // When
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            store.onAction(endpoint.action(siteID: 123) { continuation.resume(returning: $0) })
        }

        // Then
        let diagnosticError = result.failure as? UnexpectedStoreResponseError
        let error = try #require(diagnosticError)
        #expect(error.statusCode == (response == .malformedSchema ? 200 : 503))
        #expect(error.kind == (response == .malformedSchema ? .unexpectedContent : .unacceptableStatusCode))
        #expect(storage.viewStorage.countObjects(ofType: Storage.PaymentGatewayAccount.self) == 0)
        #expect(storage.viewStorage.countObjects(ofType: Storage.SiteSetting.self) == 0)
        #expect(storage.viewStorage.countObjects(ofType: Storage.SystemPlugin.self) == 0)
        #expect(settingsActions.receivedActions.isEmpty)
    }

    @Test(arguments: Endpoint.allCases, [Response.directJSON503, .malformedSchema])
    func test_remote_read_when_detection_is_omitted_then_preserves_legacy_error_type(endpoint: Endpoint, response: Response) async throws {
        // Given
        let network = MockPaymentDiagnosticResponseNetwork(response: response, expectsDetection: false)

        // When
        let result = await endpoint.fetchWithDefaultPolicy(network: network)

        // Then
        let error = try #require(result.failure)
        let isDiagnosticError = error is UnexpectedStoreResponseError
        #expect(!isDiagnosticError)
        if response == .directJSON503 {
            #expect(error is NetworkError)
        } else {
            #expect(error is DecodingError)
        }
    }
}

private final class MockPaymentDiagnosticResponseNetwork: MockNetwork, @unchecked Sendable {
    private let response: PaymentDiagnosticReadResponseTests.Response
    private let expectsDetection: Bool

    init(response: PaymentDiagnosticReadResponseTests.Response, expectsDetection: Bool) {
        self.response = response
        self.expectsDetection = expectsDetection
        super.init()
        simulatesJetpackTunnel = response == .tunnelJSON503
    }

    override func responseData(for request: URLRequestConvertible, completion: @escaping (Result<Data, Error>) -> Void) {
        #expect((request is UnexpectedResponseRequest) == expectsDetection)
        // Match the metadata recorded by the HTTP network before it calls Remote.
        (request as? UnexpectedResponseRequest)?.recordResponse(status: response == .malformedSchema ? 200 : 503,
                                                              contentType: "application/json", tunneled: response == .tunnelJSON503)
        let body = #"{"code":"maintenance","message":"Temporarily unavailable","data":{"status":503}}"#
        switch response {
        case .directJSON503:
            completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 503, response: Data(body.utf8))))
        case .tunnelJSON503:
            let envelope: [String: Any] = [
                "error": "no_response_body",
                "message": "Store response unavailable",
                "data": ["status": 503, "raw_body": body]
            ]
            do {
                let data = try JSONSerialization.data(withJSONObject: envelope)
                completion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500, response: data)))
            } catch {
                completion(.failure(error))
            }
        case .malformedSchema:
            completion(.success(Data(#"{"unrelated_field":true}"#.utf8)))
        }
    }
}
