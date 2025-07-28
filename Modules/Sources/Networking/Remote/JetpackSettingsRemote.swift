import Foundation

public protocol JetpackSettingsRemoteProtocol {
    /// Enables the Jetpack module with the provided slug
    ///
    /// - Parameters:
    ///     - siteID: The site on which we'll enable the module.
    ///     - moduleSlug: The slug for the module to enable.
    /// - Returns:
    ///     Whether the module was successfully enabled.
    func enableJetpackModule(for siteID: Int64, moduleSlug: String) async throws
}

/// Jetpack Settings: Remote endpoints
///
public final class JetpackSettingsRemote: Remote, JetpackSettingsRemoteProtocol {

    public func enableJetpackModule(for siteID: Int64, moduleSlug: String) async throws {
        let parameters = [moduleSlug: true]

        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.settings,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        return try await enqueue(request)
    }
}

// MARK: - Constants
//
public extension JetpackSettingsRemote {
    private enum Path {
        static let settings = "jetpack/v4/settings"
    }
}
