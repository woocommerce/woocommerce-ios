import SwiftUI

struct WooShippingPackageAndRatePlaceholder: View {
    @State private var showAddPackage: Bool = false
    var body: some View {
        VStack(spacing: .zero) {
            Button {
                showAddPackage.toggle()
            } label: {
                Text(Localization.addPackage)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, Layout.padding)

            VStack(spacing: Layout.textSpacing) {
                Text(Localization.placeholderTitle)
                    .font(.subheadline)
                    .bold()
                Text(Localization.placeholderMessage)
                    .subheadlineStyle()
            }
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.border), lineWidth: Layout.borderLineWidth, dashed: true)
        .sheet(isPresented: $showAddPackage) {
            WooShippingAddPackageView()
        }
    }
}

private extension WooShippingPackageAndRatePlaceholder {
    enum Layout {
        static let textSpacing: CGFloat = 8
        static let borderCornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 1
        static let padding: CGFloat = 32
    }

    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.button",
                                                  value: "Select a Package",
                                                  comment: "Button to select a package to use for a shipment in the shipping label creation flow.")
        static let placeholderTitle = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderTitle",
            value: "Select a package to get shipping rates",
            comment: "Call to action in the shipping rate section during shipping label creation, when there is no selected package."
        )
        static let placeholderMessage = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderMessage",
            value: "Enter your package's dimensions or pick a carrier package option to see the available shipping rates.",
            comment: "Message in the shipping rate section during shipping label creation, when there is no selected package."
        )
    }
}

#Preview {
    WooShippingPackageAndRatePlaceholder()
        .padding()
}
