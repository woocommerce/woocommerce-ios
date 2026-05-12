import Foundation
import enum NetworkingCore.Credentials
import WooAIAssistant

struct AIApiProxyTokenAdaptor: WPCOMTokenProviding {

    private let credentials: Credentials?

    init(credentials: Credentials?) {
        self.credentials = credentials
    }

    func token() async throws -> String {
        switch credentials {
        case .wpcom(_, let authToken, _):
            return authToken
        case .applicationPassword, .wporg, nil:
            throw AssistantError(kind: .auth, message: Localization.missingWPCOMCredentials)
        }
    }

    private enum Localization {
        static let missingWPCOMCredentials = NSLocalizedString(
            "aiAssistant.token.error.missingWPCOMCredentials",
            value: "AI Assistant requires WPCOM credentials.",
            comment: "Error shown when the chat client needs a WPCOM token but the merchant signed in with an application password or wp-org credentials."
        )
    }
}
