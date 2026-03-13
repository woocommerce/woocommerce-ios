import Codegen
import Foundation

/// Mapper: Jetpack connection data
///
struct JetpackConnectionDataMapper: Mapper {

    func map(response: Data) throws -> JetpackConnectionData {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(JetpackConnectionDataEnvelope.self, from: response).data
        } else {
            return try decoder.decode(JetpackConnectionData.self, from: response)
        }
    }
}

/// JetpackConnectionData Disposable Entity:
/// This entity allows us to parse JetpackUser with JSONDecoder.
///
public struct JetpackConnectionData: Decodable, GeneratedFakeable, GeneratedCopiable {
    /// The connection state for the authenticated user
    public let currentUser: JetpackUser

    /// Whether the site is already registered with Jetpack.
    /// This field is available only from Jetpack 14.4, so would be nil on older versions.
    /// Ref: pe5sF9-401-p2
    /// periphery: ignore - used in UI module
    public let isRegistered: Bool?

    /// Username of the Jetpack connection owner.
    /// This field is non-nil for sites that already register a connection with Jetpack.
    /// periphery: ignore - used in UI module
    public let connectionOwner: String?

    /// WP blog ID, available only if site has once connected to Jetpack.
    /// periphery: ignore - used in UI module
    public let blogID: Int64?

    /// periphery: ignore - used by codegen
    public init(currentUser: JetpackUser,
                isRegistered: Bool?,
                connectionOwner: String?,
                blogID: Int64?) {
        self.currentUser = currentUser
        self.isRegistered = isRegistered
        self.connectionOwner = connectionOwner
        self.blogID = blogID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentUser = try container.decode(JetpackUser.self, forKey: .currentUser)
        isRegistered = try container.decodeIfPresent(Bool.self, forKey: .isRegistered)
        connectionOwner = try? container.decodeIfPresent(String.self, forKey: .connectionOwner)
        blogID = currentUser.blogID // moved to data for easier access
    }

    private enum CodingKeys: String, CodingKey {
        case currentUser
        case isRegistered
        case connectionOwner
    }
}

/// JetpackConnectionDataEnvelope Disposable Entity:
/// The endpoint returns the document within a `data` key when tunneled through WPCom.
/// This entity allows us to parse the returned model with JSONDecoder.
///
private struct JetpackConnectionDataEnvelope: Decodable {
    let data: JetpackConnectionData
}
