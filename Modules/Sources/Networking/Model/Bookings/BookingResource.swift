import Codegen
import Foundation

public struct BookingResource: Hashable, Decodable, GeneratedFakeable, GeneratedCopiable {
    public let siteID: Int64
    public let id: Int64
    public let name: String
    public let qty: Int64
    public let role: String
    public let email: String?
    public let phoneNumber: String?
    public let imageID: Int64
    public let imageURL: String?
    public let description: String?

    public init(siteID: Int64,
                id: Int64,
                name: String,
                qty: Int64,
                role: String,
                email: String?,
                phoneNumber: String?,
                imageID: Int64,
                imageURL: String?,
                description: String?) {
        self.siteID = siteID
        self.id = id
        self.name = name
        self.qty = qty
        self.role = role
        self.email = email
        self.phoneNumber = phoneNumber
        self.imageID = imageID
        self.imageURL = imageURL
        self.description = description
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw BookingResourceDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(Int64.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let qty = try container.decode(Int64.self, forKey: .qty)
        let role = try container.decode(String.self, forKey: .role)
        let email = try container.decodeIfPresent(String.self, forKey: .email)
        let phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        let imageID = try container.decode(Int64.self, forKey: .imageID)
        let imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        let description = try container.decodeIfPresent(String.self, forKey: .description)

        self.init(siteID: siteID,
                  id: id,
                  name: name,
                  qty: qty,
                  role: role,
                  email: email,
                  phoneNumber: phoneNumber,
                  imageID: imageID,
                  imageURL: imageURL,
                  description: description)
    }
}

private extension BookingResource {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case qty
        case role
        case email
        case phoneNumber = "phone_number"
        case imageID = "image_id"
        case imageURL = "image_url"
        case description
    }
}

// MARK: - Decoding Errors
//
enum BookingResourceDecodingError: Error {
    case missingSiteID
}
