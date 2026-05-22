import Foundation
import enum NetworkingCore.Credentials
import WooAIAssistant

struct AIApiProxyTokenAdaptor: WPCOMTokenProviding {

    private let authToken: String?

    init(credentials: Credentials?) {
        if case .wpcom(_, let authToken, _) = credentials {
            self.authToken = authToken
        } else {
            self.authToken = nil
        }
    }

    func token() async throws -> String {
        guard let authToken else {
            throw AssistantError(kind: .auth, message: Localization.missingWPCOMCredentials)
        }
        return authToken
    }

    private enum Localization {
        static let missingWPCOMCredentials = NSLocalizedString(
            "aiAssistant.token.error.missingWPCOMCredentials",
            value: "AI Assistant requires WPCOM credentials.",
            comment: "Error shown when the chat client needs a WPCOM token but the merchant signed in with an application password or wp-org credentials."
        )
    }
}
