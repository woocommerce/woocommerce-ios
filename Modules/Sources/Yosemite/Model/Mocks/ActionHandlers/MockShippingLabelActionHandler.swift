import Foundation
import Storage

struct MockShippingLabelActionHandler: MockActionHandler {
    typealias ActionType = ShippingLabelAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            /// Not implemented
            case .synchronizeShippingLabels(_, _, let completion):
                let mockShippingLabel = ShippingLabel(
                    siteID: 0,
                    orderID: 0,
                    shippingLabelID: 0,
                    carrierID: "",
                    shipmentID: "0",
                    dateCreated: Date(),
                    packageName: "",
                    rate: 0.0,
                    currency: "",
                    trackingNumber: "",
                    serviceName: "",
                    refundableAmount: 0.0,
                    status: .unknown,
                    refund: nil,
                    originAddress: ShippingLabelAddress(
                        company: "",
                        name: "",
                        phone: "",
                        country: "",
                        state: "",
                        address1: "",
                        address2: "",
                        city: "",
                        postcode: ""
                    ),
                    destinationAddress: ShippingLabelAddress(
                        company: "",
                        name: "",
                        phone: "",
                        country: "",
                        state: "",
                        address1: "",
                        address2: "",
                        city: "",
                        postcode: ""
                    ),
                    productIDs: [],
                    productNames: [],
                    commercialInvoiceURL: nil,
                    usedDate: nil,
                    expiryDate: nil,
                    hazmatCategory: nil
                )
                completion(.success([mockShippingLabel]))
            case .checkCreationEligibility(_, _, let onCompletion):
                onCompletion(false)
            default: unimplementedAction(action: action)
        }
    }
}
