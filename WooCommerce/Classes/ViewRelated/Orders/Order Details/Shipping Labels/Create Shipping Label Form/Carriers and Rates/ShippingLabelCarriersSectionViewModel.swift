import SwiftUI

struct ShippingLabelCarriersSectionViewModel: Identifiable {
    internal let id = UUID()

    let packageNumber: Int
    var rows: [ShippingLabelCarrierRowViewModel] = []
}
