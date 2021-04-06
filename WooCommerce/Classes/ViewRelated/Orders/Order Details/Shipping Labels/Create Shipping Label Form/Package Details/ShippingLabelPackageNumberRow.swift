import SwiftUI
import Foundation

struct ShippingLabelPackageNumberRow: View {
    let packageNumber: Int
    let numberOfItems: Int

    init(packageNumber: Int, numberOfItems: Int) {
        self.packageNumber = packageNumber
        self.numberOfItems = numberOfItems
    }

    var body: some View {
        HStack {
            Text(String(format: Localization.package, packageNumber))
                .font(.headline)
            Text(String(format: Localization.numberOfItems, numberOfItems))
                .font(.body)
            Spacer()
        }
        .frame(height: Constants.height)
        .padding([.leading, .trailing], Constants.padding)
    }
}

private extension ShippingLabelPackageNumberRow {
    enum Localization {
        static let package = NSLocalizedString("Package %1$d", comment: "Package term in Shipping Labels. Reads like Package 1")
        static let numberOfItems = NSLocalizedString("- %1$d items", comment: "Number of items in packages in Shipping Labels. Reads like - 10 items")
    }

    enum Constants {
        static let height: CGFloat = 44
        static let padding: CGFloat = 44
    }
}


struct ShippingLabelPackageNumberRow_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: 10)
            .previewLayout(.fixed(width: 375, height: 50))

        ShippingLabelPackageNumberRow(packageNumber: 7, numberOfItems: 1)
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
