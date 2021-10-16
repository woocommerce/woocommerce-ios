import SwiftUI
import Foundation

struct ShippingLabelCarrierSectionHeader: View {
    let packageNumber: Int

    init(packageNumber: Int) {
        self.packageNumber = packageNumber
    }

    var body: some View {
        HStack {
            Text(String(format: Localization.package, packageNumber))
                .font(.headline)
        }
    }
}

private extension ShippingLabelCarrierSectionHeader {
    enum Localization {
        static let package = NSLocalizedString("Package %1$d", comment: "Package term in Shipping Labels. Reads like Package 1")
    }
}


struct ShippingLabelCarrierCompactableRow_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelCarrierSectionHeader(packageNumber: 1)
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelCarrierSectionHeader(packageNumber: 7)
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
