/// Represent shipping scale data
///

public struct ShippingScaleStatus: Decodable {
    /// Last weight recorded in ounces.
    ///
    public let weight: Float

    /// Unix datetime when last weight was recorded.
    ///
    public let datetime: UInt64

    public init(
        weight: Float,
        datetime: UInt64
    ) {
        self.weight = weight
        self.datetime = datetime
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let weight = try container.decode(Float.self, forKey: .weight)
        let datetime = try container.decode(UInt64.self, forKey: .datetime)

        self.init(
            weight: weight,
            datetime: datetime
        )
    }
}

private extension ShippingScaleStatus {
    enum CodingKeys: String, CodingKey {
        case weight
        case datetime
    }
}
