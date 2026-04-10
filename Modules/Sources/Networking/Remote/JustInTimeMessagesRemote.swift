import Foundation

public protocol JustInTimeMessagesRemoteProtocol {
    func loadAllJustInTimeMessages(for siteID: Int64,
                                   messagePath: JustInTimeMessagesRemote.MessagePath,
                                   query: [String: String?]?,
                                   locale: String?) async throws -> [JustInTimeMessage]
    func dismissJustInTimeMessage(for siteID: Int64,
                                  messageID: String,
                                  featureClass: String) async throws -> Bool
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
    ///     - query: A dictionary of "query parameters" to include in the JITM request payload
    ///     - locale: the locale identifier (language and region only, e.g. en_US) for the current device.
    /// - Returns:
    ///     Async result with an array of `[JustInTimeMessage]` (usually contains one element) or an error
    ///
    public func loadAllJustInTimeMessages(for siteID: Int64,
                                          messagePath: JustInTimeMessagesRemote.MessagePath,
                                          query: [String: String?]?,
                                          locale: String?) async throws -> [JustInTimeMessage] {
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     locale: locale,
                                     path: Path.jitm,
                                     parameters: getParameters(messagePath: messagePath,
                                                               query: query),
                                     availableAsRESTRequest: true)

        let mapper = JustInTimeMessageListMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    private func getParameters(messagePath: JustInTimeMessagesRemote.MessagePath,
                                    query: [String: String?]?) -> [String: String] {
        var parameters = [ParameterKey.messagePath: messagePath.requestValue]
        if let query = query,
           let queryString = justInTimeMessageQuery(from: query) {
            parameters[ParameterKey.query] = queryString
        }
        return parameters
    }

    private func justInTimeMessageQuery(from parameters: [String: String?]) -> String? {
        let queryItems = parameters.map { (key: String, value: String?) in
            URLQueryItem(name: key, value: value)
        }
        var components = URLComponents()
        /// This is a workaround for a backend bug where only the first param can be used for targeting JITMs.
        /// `build_type` is the most important, but absent in release builds. In release builds, `platform` is the most important
        /// This can be removed when the backend bug is fixed, order should not matter here.
        components.queryItems = queryItems.sorted(by: { lhs, rhs in
            switch (lhs.name, rhs.name) {
            case (_, "build_type"):
                return false
            case ("build_type", "platform"):
                return true
            case (_, "platform"):
                return false
            case ("platform", _):
                return true
            default:
                return lhs.name < rhs.name
            }
        })
        return components.query
    }

    /// Dismisses a `JustInTimeMessage` using the API.
    ///
    /// - Parameters:
    ///     - siteID: The site for which we'll dismiss a JustInTimeMessage
    ///     - messageID: The ID of the JustInTimeMessage that was dismissed
    ///     - featureClass: The featureClass of the JustInTimeMessages that should be dismissed
    /// - Returns:
    ///     Async result with a `Bool` indicating whether dismissal was successful, or an error
    ///
    public func dismissJustInTimeMessage(for siteID: Int64,
                                         messageID: String,
                                         featureClass: String) async throws -> Bool {

        let parameters = [ParameterKey.featureClass: featureClass,
                          ParameterKey.messageID: messageID]

        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.jitm,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        return try await enqueue(request, mapper: DataBoolMapper())
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
        static let featureClass = "feature_class"
        static let messageID = "id"
        static let query = "query"
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
