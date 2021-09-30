import SwiftUI
import Foundation

struct ShippingLabelCarrierCompactableRow: View {
    let packageNumber: Int
    let packageName: String
    let isValid: Bool

    init(packageNumber: Int, packageName: String, isValid: Bool = true) {
        self.packageNumber = packageNumber
        self.packageName = packageName
        self.isValid = isValid
    }

    var body: some View {
        HStack {
            Text(String(format: Localization.package, packageNumber))
                .font(.headline)
            Text("- " + packageName)
                .font(.body)
            Spacer()
            Image(uiImage: .noticeImage)
                .foregroundColor(Color(.error))
                .renderedIf(!isValid)
        }
    }
}

private extension ShippingLabelCarrierCompactableRow {
    enum Localization {
        static let package = NSLocalizedString("Package %1$d", comment: "Package term in Shipping Labels. Reads like Package 1")
    }
}


struct ShippingLabelCarrierCompactableRow_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelCarrierCompactableRow(packageNumber: 1, packageName: "Small package")
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelCarrierCompactableRow(packageNumber: 7, packageName: "Small package")
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelCarrierCompactableRow(packageNumber: 7, packageName: "Big package 1", isValid: false)
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
