import SwiftUI

struct WooShippingHazmatRow: View {
    /// Whether the interactions (navigation/setting selection) are enabled.
    let enabled: Bool

    var body: some View {
        Button(action: {
            // TODO: show sheet
        }) {
            AdaptiveStack {
                Text(Localization.hazmatLabel)
                    .bodyStyle()
                Spacer()
                Text("No") // TODO: Replace with actual hazmat selection for package
                    .secondaryBodyStyle()
                if enabled {
                    Image(uiImage: .chevronImage) // TODO: Replace with actual navigation to hazmat declaration screen
                        .secondaryBodyStyle()
                }
            }
            .padding(.vertical, Layout.verticalPadding)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private extension WooShippingHazmatRow {
    enum Layout {
        static let backgroundRadius: CGFloat = 8
        static let verticalPadding: CGFloat = 24
    }

    enum Localization {
        static let hazmatLabel = NSLocalizedString("wooShipping.createLabel.hazmatLabel",
                                                   value: "Are you shipping dangerous goods or hazardous materials?",
                                                   comment: "Label for section in shipping label creation to declare when a package contains hazardous materials.")
    }
}

#Preview {
    WooShippingHazmatRow(enabled: true)
        .padding()
}
