import Foundation

public protocol JustInTimeMessagesRemoteProtocol {
    func loadAllJustInTimeMessages(for siteID: Int64,
                                   messagePath: JustInTimeMessagesRemote.MessagePath) async -> Result<[JustInTimeMessage], Error>
}

/// Just In Time Messages: Remote endpoints
///
public final class JustInTimeMessagesRemote: Remote, JustInTimeMessagesRemoteProtocol {
    // MARK: - GET Just In Time Messages

    /// Retrieves all of the `JustInTimeMessage`s from the API.
    ///
    /// - Parameters:
    ///     - siteID: The site for which we'll fetch JustInTimeMessages.
    ///     - messagePath: The location for JITMs to be displayed
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllJustInTimeMessages(for siteID: Int64,
                                          messagePath: JustInTimeMessagesRemote.MessagePath) async -> Result<[JustInTimeMessage], Error> {
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.jitm,
                                     parameters: [ParameterKey.messagePath: messagePath.requestValue])

        let mapper = JustInTimeMessageListMapper(siteID: siteID)

        do {
            let result = try await enqueue(request, mapper: mapper)
            return result
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Constants
//
public extension JustInTimeMessagesRemote {
    private enum Path {
        static let jitm = "jetpack/v4/jitm"
    }

    private enum ParameterKey {
        static let messagePath = "message_path"
    }

    /// Message Path parameter
    ///
    struct MessagePath {
        public let app: MessagePath.App
        public let screen: String
        public let hook: MessagePath.Hook

        public init(app: MessagePath.App,
                    screen: String,
                    hook: MessagePath.Hook) {
            self.app = app
            self.screen = screen
            self.hook = hook
        }

        public enum App: String {
            case wooMobile = "woomobile"
        }

        public enum Hook: String {
            case adminNotices = "admin_notices"
        }

        var requestValue: String {
            "\(app.rawValue):\(screen):\(hook.rawValue)"
        }
    }
}
