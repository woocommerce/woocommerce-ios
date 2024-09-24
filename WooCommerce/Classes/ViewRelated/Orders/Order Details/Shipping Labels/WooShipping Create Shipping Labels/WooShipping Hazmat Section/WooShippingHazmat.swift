import SwiftUI

struct WooShippingHazmat: View {
    var body: some View {
        AdaptiveStack {
            Text(Localization.hazmatLabel)
                .bodyStyle()
            Spacer()
            Text("No") // TODO: Replace with actual hazmat selection for package
                .secondaryBodyStyle()
            Image(uiImage: .chevronImage) // TODO: Replace with actual navigation to hazmat declaration screen
                .secondaryBodyStyle()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: Layout.backgroundRadius).fill(Color(.quaternarySystemFill)))
    }
}

private extension WooShippingHazmat {
    enum Layout {
        static let backgroundRadius: CGFloat = 8
    }

    enum Localization {
        static let hazmatLabel = NSLocalizedString("wooShipping.createLabel.hazmatLabel",
                                                   value: "Are you shipping dangerous goods or hazardous materials?",
                                                   comment: "Label for section in shipping label creation to declare when a package contains hazardous materials.")
    }
}

#Preview {
    WooShippingHazmat()
}
