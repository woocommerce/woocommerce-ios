import Foundation

public protocol JustInTimeMessagesRemoteProtocol {
    func loadAllJustInTimeMessages(for siteID: Int64,
                                   messagePath: JustInTimeMessagesRemote.MessagePath,
                                   query: [String: String?]?,
                                   locale: String?) async -> Result<[JustInTimeMessage], Error>
    func dismissJustInTimeMessage(for siteID: Int64,
                                  messageID: String,
                                  featureClass: String) async -> Result<Bool, Error>
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
                                          locale: String?) async -> Result<[JustInTimeMessage], Error> {
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     locale: locale,
                                     path: Path.jitm,
                                     parameters: getParameters(messagePath: messagePath,
                                                               query: query))

        let mapper = JustInTimeMessageListMapper(siteID: siteID)

        do {
            let result = try await enqueue(request, mapper: mapper)
            return result
        } catch {
            return .failure(error)
        }
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
        components.queryItems = queryItems
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
                                         featureClass: String) async -> Result<Bool, Error> {

        let parameters = [ParameterKey.featureClass: featureClass,
                          ParameterKey.messageID: messageID]

        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.jitm,
                                     parameters: parameters)

        do {
            let result = try await enqueue(request, mapper: DataBoolMapper())
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
