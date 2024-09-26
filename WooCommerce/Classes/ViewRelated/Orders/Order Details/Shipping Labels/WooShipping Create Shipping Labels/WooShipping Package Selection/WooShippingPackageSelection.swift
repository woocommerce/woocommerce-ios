import SwiftUI

struct WooShippingPackageSelection: View {
    @State var showAddPackage: Bool = false

    var body: some View {
        Button {
            showAddPackage.toggle()
        } label: {
            Text(Localization.addPackage)
        }
        .buttonStyle(PrimaryButtonStyle())
        .sheet(isPresented: $showAddPackage) {
            WooShippingAddPackageView()
        }
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
