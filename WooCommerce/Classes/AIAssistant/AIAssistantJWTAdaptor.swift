import Foundation
import struct NetworkingCore.DotcomRequest
import enum NetworkingCore.WordPressAPIVersion
import protocol NetworkingCore.Network
import struct Alamofire.HTTPMethod
import WooAIAssistant

struct AIAssistantJWTAdaptor: @unchecked Sendable, AssistantJWTProviding {

    private let provider: WpComJetpackAIJWTProvider

    init(blogID: Int64, network: Network) {
        let mint: WpComJetpackAIJWTProvider.Mint = { siteID in
            try await Self.mint(siteID: siteID, network: network)
        }
        self.provider = WpComJetpackAIJWTProvider(blogID: blogID, mint: mint)
    }

    func currentJWT() async throws -> String {
        try await provider.currentJWT()
    }

    func invalidate() async {
        await provider.invalidate()
    }

    private static func mint(siteID: Int64, network: Network) async throws -> String {
        let path = "sites/\(siteID)/jetpack-openai-query/jwt"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path)
        let (data, _) = try await network.responseDataAndHeaders(for: request)
        return try Self.extractToken(from: data)
    }

    private static func extractToken(from data: Data) throws -> String {
        struct Response: Decodable {
            let token: String
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard !decoded.token.isEmpty else {
            throw AssistantError(kind: .auth, message: Localization.invalidJWTResponse)
        }
        return decoded.token
    }

    private enum Localization {
        static let invalidJWTResponse = NSLocalizedString(
            "aiAssistant.jwt.error.invalidResponse",
            value: "The store returned an empty Jetpack AI token.",
            comment: "Error shown when the JWT mint endpoint returns an empty token string."
        )
    }
}
