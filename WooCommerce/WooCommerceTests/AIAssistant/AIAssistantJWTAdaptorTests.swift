import Foundation
import Combine
import Testing
import Alamofire
@testable import Networking
@testable import NetworkingCore
@testable import WooCommerce

@MainActor
struct AIAssistantJWTAdaptorTests {

    @Test
    func test_jwt_when_wpcom_credentials_then_calls_jetpack_openai_query_jwt() async throws {
        // Given
        let token = makeFakeJWT(blogID: 99, expiresIn: 3600)
        let network = StubNetwork(token: token)
        let credentials: Credentials = .wpcom(username: "u", authToken: "t", siteAddress: "https://store.test")
        let sut = AIAssistantJWTAdaptor(blogID: 99, network: network, credentials: credentials)

        // When
        let result = try await sut.currentJWT()

        // Then
        #expect(result == token)
        #expect(network.lastPath?.contains("sites/99/jetpack-openai-query/jwt") == true)
    }

    @Test
    func test_jwt_when_applicationPassword_credentials_then_routes_through_dotcom_request() async throws {
        // Given
        let token = makeFakeJWT(blogID: 42, expiresIn: 3600)
        let network = StubNetwork(token: token)
        let credentials: Credentials = .applicationPassword(username: "u", password: "p", siteAddress: "https://store.test")
        let sut = AIAssistantJWTAdaptor(blogID: 42, network: network, credentials: credentials)

        // When
        let result = try await sut.currentJWT()

        // Then
        #expect(result == token)
        #expect(network.lastPath?.contains("sites/42/jetpack-openai-query/jwt") == true)
    }

    @Test
    func test_jwt_when_wporg_credentials_then_throws_unsupported_auth() async {
        // Given
        let token = makeFakeJWT(blogID: 7, expiresIn: 3600)
        let network = StubNetwork(token: token)
        let credentials: Credentials = .wporg(username: "u", password: "p", siteAddress: "https://store.test")
        let sut = AIAssistantJWTAdaptor(blogID: 7, network: network, credentials: credentials)

        // When
        var didThrow = false
        do {
            _ = try await sut.currentJWT()
        } catch {
            didThrow = true
        }

        // Then
        #expect(didThrow == true)
        #expect(network.lastPath == nil)
    }
}

private final class StubNetwork: Network, @unchecked Sendable {
    let token: String
    private(set) var lastPath: String?

    init(token: String) {
        self.token = token
    }

    var session: URLSession { URLSession(configuration: .default) }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        let result = synthesize(for: request)
        completion(result, nil)
    }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.success(synthesize(for: request)))
    }

    func responseDataAndHeaders(for request: URLRequestConvertible) async throws -> (Data, ResponseHeaders?) {
        return (synthesize(for: request), nil)
    }

    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Result<Data, Error>, Never> {
        Just(.success(synthesize(for: request))).eraseToAnyPublisher()
    }

    func uploadMultipartFormData(multipartFormData: @escaping (NetworkingCore.MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void) {
        completion(synthesize(for: request), nil)
    }

    private func synthesize(for request: URLRequestConvertible) -> Data {
        if let dotcom = request as? DotcomRequest {
            lastPath = dotcom.path
        }
        let payload = ["token": token]
        return (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
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
