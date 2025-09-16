import Foundation
import Networking
import struct Combine.AnyPublisher

/// Protocol for POS site setting service that manages WooCommerce feature flags.
public protocol POSSiteSettingServiceProtocol {
    /// Enables or disables a specific feature in the site WC settings.
    /// - Parameters:
    ///   - siteID: The site ID for which to update the feature setting.
    ///   - feature: The feature to enable or disable.
    ///   - enabled: Whether the feature should be enabled (true) or disabled (false).
    /// - Returns: A boolean indicating the updated feature status.
    /// - Throws: Error if the request fails or the setting cannot be updated.
    func setFeature(siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool
}

/// Service for managing Point of Sale related site settings.
public final class POSSiteSettingService: POSSiteSettingServiceProtocol {
    private let remote: SiteSettingsRemoteProtocol

    public init(credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.remote = SiteSettingsRemote(network: network)
    }

    /// Test-friendly initializer that accepts a remote implementation.
    /// - Parameter remote: The remote service implementation to use for network requests.
    init(remote: SiteSettingsRemoteProtocol) {
        self.remote = remote
    }

    public func setFeature(siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool {
        try await remote.setFeature(for: siteID, feature: feature, enabled: enabled)
    }
}
