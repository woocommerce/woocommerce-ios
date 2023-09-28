/// A wrapper of shipping labels and settings from `Load Shipping Labels` response.
public struct OrderShippingLabelListResponse {
    /// A list of shipping labels.
    public let shippingLabels: [ShippingLabel]

    /// Shipping label settings specific to an order's shipping labels.
    public let settings: ShippingLabelSettings
}

/// Mapper: Order Shipping Label List & Settings
///
struct OrderShippingLabelListMapper: Mapper {
    /// Site ID associated to the shipping labels that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the shipping label endpoints.
    ///
    let siteID: Int64

    /// Order ID associated to the shipping labels that will be parsed.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into OrderShippingLabelListResponse.
    ///
    func map(response: Data) throws -> OrderShippingLabelListResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        let data: OrderShippingLabelListData = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(Envelope<OrderShippingLabelListData>.self, from: response).data
            } else {
                return try decoder.decode(OrderShippingLabelListData.self, from: response)
            }
        }()
        return OrderShippingLabelListResponse(shippingLabels: data.shippingLabels, settings: data.settings)
    }
}

/// Disposable Entity:
/// Data that are inside the `data` level of `Load Shipping Labels` response.
///
private struct OrderShippingLabelListData: Decodable {
    let shippingLabels: [ShippingLabel]
    let settings: ShippingLabelSettings

    init(shippingLabels: [ShippingLabel], settings: ShippingLabelSettings) {
        self.shippingLabels = shippingLabels
        self.settings = settings
    }

    init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw OrderShippingLabelListDecodingError.missingSiteID
        }

        guard let orderID = decoder.userInfo[.orderID] as? Int64 else {
            throw OrderShippingLabelListDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Shipping label settings.
        let paperSizeRawValue = try container.decode(String.self, forKey: .paperSize)
        let paperSize = ShippingLabelPaperSize(rawValue: paperSizeRawValue)

        let settings = ShippingLabelSettings(siteID: siteID, orderID: orderID, paperSize: paperSize)

        // Shipping labels.
        let formData = try container.decode(OrderShippingLabelListFormData.self, forKey: .formData)
        let shippingLabelsWithoutAddresses = try container.decode([ShippingLabel].self, forKey: .labelsData)
        // Filters only labels with a tracking number and status `.purchased`.
        // Then populates each shipping label's `originAddress` and `destinationAddress` from `formData` because they are not available
        // in each shipping label response.
        let shippingLabels = shippingLabelsWithoutAddresses
            .filter { !$0.trackingNumber.isEmpty && $0.status == .purchased }
            .map {
                $0.copy(originAddress: formData.originAddress, destinationAddress: formData.destinationAddress)
            }

        self.init(shippingLabels: shippingLabels, settings: settings)
    }

    private enum CodingKeys: String, CodingKey {
        case formData
        case paperSize
        case labelsData
    }
}

/// Disposable Entity:
/// Data that are inside the `data.formData` level of `Load Shipping Labels` response.
///
private struct OrderShippingLabelListFormData: Decodable {
    let originAddress: ShippingLabelAddress
    let destinationAddress: ShippingLabelAddress

    private enum CodingKeys: String, CodingKey {
        case originAddress = "origin"
        case destinationAddress = "destination"
    }
}

// MARK: - Decoding Errors
//
enum OrderShippingLabelListDecodingError: Error {
    case missingSiteID
    case missingOrderID
}
