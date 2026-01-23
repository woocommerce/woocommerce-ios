import SwiftUI
import Foundation

struct ShippingLabelPackageNumberRow: View {
    let packageNumber: Int
    let numberOfItems: Int
    let isValid: Bool

    init(packageNumber: Int, numberOfItems: Int, isValid: Bool = true) {
        self.packageNumber = packageNumber
        self.numberOfItems = numberOfItems
        self.isValid = isValid
    }

    var body: some View {
        HStack {
            Text(String(format: Localization.package, packageNumber))
                .font(.headline)
            if numberOfItems <= 1 {
                Text(String(format: Localization.numberOfItem, numberOfItems))
                    .font(.body)
            }
            else {
                Text(String(format: Localization.numberOfItems, numberOfItems))
                    .font(.body)
            }
            Spacer()
            Image(uiImage: .noticeImage)
                .foregroundColor(Color(.error))
                .renderedIf(!isValid)
        }
    }
}

private extension ShippingLabelPackageNumberRow {
    enum Localization {
        static let package = NSLocalizedString("Package %1$d", comment: "Package term in Shipping Labels. Reads like Package 1")
        static let numberOfItems = NSLocalizedString("- %1$d items",
                                                     comment: "This text appears as a label in the shipping label creation flow, specifically showing the number of items contained in a package when there are multiple items (2 or more). It displays below the package number as part of a package details row.")
        static let numberOfItem = NSLocalizedString("- %1$d item",
                                                    comment: "This text appears as a label in the shipping label creation flow, specifically showing the number of items in a package when there is exactly one item. It displays below the package number (e.g., 'Package 1') and uses a dash prefix to indicate it's supplementary information about the package contents.")
    }
}


struct ShippingLabelPackageNumberRow_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: 10)
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelPackageNumberRow(packageNumber: 7, numberOfItems: 1)
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelPackageNumberRow(packageNumber: 7, numberOfItems: 1, isValid: false)
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
