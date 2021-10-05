import SwiftUI

struct ShippingLabelCarriersSectionViewModel: Identifiable {
    internal let id = UUID()

    let packageNumber: Int
    let rows: [ShippingLabelCarrierRowViewModel]
}
