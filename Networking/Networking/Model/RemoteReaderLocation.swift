/// Represent a Remote Reader Location Entity.
///
public struct RemoteReaderLocation: Decodable {
    public let locationID: String
    public let city: String?
    public let country: String
    public let addressLine1: String
    public let addressLine2: String?
    public let postalCode: String?
    public let stateProvinceRegion: String?
    public let displayName: String
    public let liveMode: Bool

    public init(
        locationID: String,
        city: String? = nil,
        country: String,
        addressLine1: String,
        addressLine2: String? = nil,
        postalCode: String? = nil,
        stateProvinceRegion: String? = nil,
        displayName: String,
        liveMode: Bool
    ) {
        self.locationID = locationID
        self.city = city
        self.country = country
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.postalCode = postalCode
        self.stateProvinceRegion = stateProvinceRegion
        self.displayName = displayName
        self.liveMode = liveMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let locationID = try container.decode(String.self, forKey: .locationID)
        let addressContainer = try container.nestedContainer(keyedBy: AddressCodingKeys.self, forKey: .address)
        let city = try addressContainer.decode(String.self, forKey: .city)
        let country = try addressContainer.decode(String.self, forKey: .country)
        let addressLine1 = try addressContainer.decode(String.self, forKey: .addressLine1)
        let addressLine2 = try addressContainer.decode(String.self, forKey: .addressLine2)
        let postalCode = try addressContainer.decode(String.self, forKey: .postalCode)
        let stateProvinceRegion = try addressContainer.decode(String.self, forKey: .stateProvinceRegion)
        let displayName = try container.decode(String.self, forKey: .displayName)
        let liveMode = try container.decode(Bool.self, forKey: .liveMode)

        self.init(
            locationID: locationID,
            city: city,
            country: country,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            postalCode: postalCode,
            stateProvinceRegion: stateProvinceRegion,
            displayName: displayName,
            liveMode: liveMode
        )
    }
}

private extension RemoteReaderLocation {
    enum CodingKeys: String, CodingKey {
        case locationID = "id"
        case address = "address"
        case displayName = "display_name"
        case liveMode = "livemode"
    }

    enum AddressCodingKeys: String, CodingKey {
        case city = "city"
        case country = "country"
        case addressLine1 = "line1"
        case addressLine2 = "line2"
        case postalCode = "postal_code"
        case stateProvinceRegion = "state"
    }
}
