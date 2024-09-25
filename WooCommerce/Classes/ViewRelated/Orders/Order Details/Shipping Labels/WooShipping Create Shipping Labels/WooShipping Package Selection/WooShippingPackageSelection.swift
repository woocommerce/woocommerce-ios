import SwiftUI

struct WooShippingPackageSelection: View {
    var body: some View {
        Button {
            // TODO-13551: Open package selection UI
        } label: {
            Text(Localization.addPackage)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

private extension WooShippingPackageSelection {
    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.button",
                                                  value: "Add a Package",
                                                  comment: "Button to select a package to use for a shipment in the shipping label creation flow.")
    }
}

#Preview {
    WooShippingPackageSelection()
}
