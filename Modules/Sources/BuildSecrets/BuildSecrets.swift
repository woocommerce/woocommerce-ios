import Foundation

public struct BuildSecrets: Sendable {

    public struct OAuth: Sendable {
        public let appId: String
        public let secret: String

        public init(appId: String, secret: String) {
            self.appId = appId
            self.secret = secret
        }
    }

    public struct Google: Sendable {
        public let clientId: String
        public let serverId: String

        public init(clientId: String, serverId: String) {
            self.clientId = clientId
            self.serverId = serverId
        }
    }

    public struct Zendesk: Sendable {
        public let appId: String
        public let url: String
        public let clientId: String

        public init(appId: String, url: String, clientId: String) {
            self.appId = appId
            self.url = url
            self.clientId = clientId
        }
    }

    public let oauth: OAuth
    public let google: Google
    public let zendesk: Zendesk
    public let tracksPrefix: String
    public let sentryDSN: String
    public let loggingEncryptionKey: String

    public init(
        oauth: OAuth,
        google: Google,
        zendesk: Zendesk,
        tracksPrefix: String,
        sentryDSN: String,
        loggingEncryptionKey: String
    ) {
        self.oauth = oauth
        self.google = google
        self.zendesk = zendesk
        self.tracksPrefix = tracksPrefix
        self.sentryDSN = sentryDSN
        self.loggingEncryptionKey = loggingEncryptionKey
    }
}

extension BuildSecrets {

    public static let dummy = BuildSecrets(
        oauth: .init(appId: "", secret: ""),
        google: .init(clientId: "", serverId: ""),
        zendesk: .init(appId: "", url: "", clientId: ""),
        tracksPrefix: "",
        sentryDSN: "",
        loggingEncryptionKey: ""
    )
}

extension BuildSecrets {

    nonisolated(unsafe) static var configuredSecrets: BuildSecrets?

    public static var current: BuildSecrets {
        switch BuildSecretsEnvironment.current {
        case .preview, .test:
            return .dummy
        case .live:
            guard let secrets = configuredSecrets else {
                fatalError("Attempted to access BuildSecrets before calling configure(secrets:).")
            }
            return secrets
        }
    }
}
