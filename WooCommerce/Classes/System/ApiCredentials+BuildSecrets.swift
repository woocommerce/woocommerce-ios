import BuildSecrets

extension ApiCredentials {

    static func toSecrets() -> BuildSecrets {
        BuildSecrets(
            oauth: .init(
                appId: dotcomAppId,
                secret: dotcomSecret
            ),
            google: .init(
                clientId: googleClientId,
                serverId: googleServerId
            ),
            zendesk: .init(
                appId: zendeskAppId,
                url: zendeskUrl,
                clientId: zendeskClientId
            ),
            tracksPrefix: tracksPrefix,
            sentryDSN: sentryDSN,
            loggingEncryptionKey: loggingEncryptionKey
        )
    }
}
