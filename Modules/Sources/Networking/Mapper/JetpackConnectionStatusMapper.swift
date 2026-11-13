import Foundation

/// Mapper: Jetpack connection status
///
struct JetpackConnectionStatusMapper: Mapper {

    func map(response: Data) throws -> JetpackConnectionStatus {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(JetpackConnectionStatusEnvelope.self, from: response).data
        } else {
            return try decoder.decode(JetpackConnectionStatus.self, from: response)
        }
    }
}

/// JetpackConnectionStatus Disposable Entity:
/// Models the response of the bare `jetpack/v4/connection` endpoint. Unlike `jetpack/v4/connection/data`,
/// this endpoint is not gated by Jetpack capabilities, so it remains reachable even when the site is in
/// Offline Mode (which otherwise makes the connection data endpoint return a 403).
///
public struct JetpackConnectionStatus: Decodable {
    /// The site's Jetpack Offline Mode state, if reported.
    public let offlineMode: OfflineMode?

    /// Whether the site's Jetpack is currently in Offline Mode.
    public var isInOfflineMode: Bool {
        offlineMode?.isActive == true
    }

    public init(offlineMode: OfflineMode?) {
        self.offlineMode = offlineMode
    }

    public struct OfflineMode: Decodable {
        /// Whether Offline Mode is currently active for the site.
        public let isActive: Bool?

        public init(isActive: Bool?) {
            self.isActive = isActive
        }
    }
}

/// JetpackConnectionStatusEnvelope Disposable Entity:
/// The endpoint returns the document within a `data` key when tunneled through WPCom.
/// This entity allows us to parse the returned model with JSONDecoder.
///
private struct JetpackConnectionStatusEnvelope: Decodable {
    let data: JetpackConnectionStatus
}
