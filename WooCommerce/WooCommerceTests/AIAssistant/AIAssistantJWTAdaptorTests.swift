import Foundation
import Combine
import Testing
import Alamofire
import WooAIAssistant
@testable import Networking
@testable import NetworkingCore
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AIAssistantJWTAdaptorTests {

    @Test
    func test_jwt_when_called_then_routes_through_jetpack_openai_query_endpoint() async throws {
        // Given
        let token = makeFakeJWT(blogID: 99, expiresIn: 3600)
        let network = StubNetwork(behavior: .returnToken(token))
        let sut = AIAssistantJWTAdaptor(blogID: 99, network: network)

        // When
        let result = try await sut.currentJWT()

        // Then
        #expect(result == token)
        #expect(network.lastPath?.contains("sites/99/jetpack-openai-query/jwt") == true)
    }

    @Test
    func test_jwt_when_server_returns_empty_token_then_throws_invalid_response_error() async {
        // Given
        let network = StubNetwork(behavior: .returnToken(""))
        let sut = AIAssistantJWTAdaptor(blogID: 99, network: network)

        // When
        var caught: AssistantError?
        do {
            _ = try await sut.currentJWT()
        } catch let error as AssistantError {
            caught = error
        } catch {}

        // Then
        #expect(caught?.kind == .auth)
    }

    @Test
    func test_jwt_when_network_throws_then_error_propagates_to_caller() async {
        // Given
        let stubError = NSError(domain: "TestDomain", code: 99, userInfo: nil)
        let network = StubNetwork(behavior: .throwError(stubError))
        let sut = AIAssistantJWTAdaptor(blogID: 99, network: network)

        // When
        var caught: NSError?
        do {
            _ = try await sut.currentJWT()
        } catch let error as NSError {
            caught = error
        }

        // Then
        #expect(caught?.domain == "TestDomain")
        #expect(caught?.code == 99)
    }

    @Test
    func test_jwt_when_invalidate_then_next_currentJWT_calls_mint_again() async throws {
        // Given
        let token = makeFakeJWT(blogID: 99, expiresIn: 3600)
        let network = StubNetwork(behavior: .returnToken(token))
        let sut = AIAssistantJWTAdaptor(blogID: 99, network: network)

        // When
        _ = try await sut.currentJWT()
        let cachedCallCount = network.callCount
        _ = try await sut.currentJWT()
        let stillCached = network.callCount
        await sut.invalidate()
        _ = try await sut.currentJWT()
        let afterInvalidate = network.callCount

        // Then
        #expect(cachedCallCount == 1)
        #expect(stillCached == 1)
        #expect(afterInvalidate == 2)
    }
}

private final class StubNetwork: Network, @unchecked Sendable {
    enum Behavior {
        case returnToken(String)
        case throwError(Error)
    }

    let behavior: Behavior
    nonisolated(unsafe) private(set) var lastPath: String?
    nonisolated(unsafe) private(set) var callCount: Int = 0

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    var session: URLSession { URLSession(configuration: .default) }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        switch behavior {
        case .returnToken:
            completion(synthesize(for: request), nil)
        case .throwError(let error):
            completion(nil, error)
        }
    }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Result<Data, Error>) -> Void) {
        switch behavior {
        case .returnToken:
            completion(.success(synthesize(for: request)))
        case .throwError(let error):
            completion(.failure(error))
        }
    }

    func responseDataAndHeaders(for request: URLRequestConvertible) async throws -> (Data, ResponseHeaders?) {
        switch behavior {
        case .returnToken:
            return (synthesize(for: request), nil)
        case .throwError(let error):
            recordPath(for: request)
            throw error
        }
    }

    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Result<Data, Error>, Never> {
        switch behavior {
        case .returnToken:
            return Just(.success(synthesize(for: request))).eraseToAnyPublisher()
        case .throwError(let error):
            return Just(.failure(error)).eraseToAnyPublisher()
        }
    }

    func uploadMultipartFormData(multipartFormData: @escaping (NetworkingCore.MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void) {
        switch behavior {
        case .returnToken:
            completion(synthesize(for: request), nil)
        case .throwError(let error):
            completion(nil, error)
        }
    }

    private func synthesize(for request: URLRequestConvertible) -> Data {
        recordPath(for: request)
        guard case .returnToken(let token) = behavior else { return Data() }
        let payload = ["token": token]
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    private func recordPath(for request: URLRequestConvertible) {
        callCount += 1
        if let dotcom = request as? DotcomRequest {
            lastPath = dotcom.path
        }
    }
}

private func makeFakeJWT(blogID: Int64, expiresIn: TimeInterval) -> String {
    let header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}"
    let exp = Int64(Date().addingTimeInterval(expiresIn).timeIntervalSince1970)
    let payloadJSON = "{\"blog_id\":\(blogID),\"exp\":\(exp)}"
    let signature = "sig"
    return [header, payloadJSON, signature].map(base64URLEncode).joined(separator: ".")
}

private func base64URLEncode(_ text: String) -> String {
    Data(text.utf8).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}
