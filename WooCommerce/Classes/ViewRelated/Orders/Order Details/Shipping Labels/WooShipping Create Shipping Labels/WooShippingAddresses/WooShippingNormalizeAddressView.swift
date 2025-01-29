import SwiftUI

struct WooShippingNormalizeAddressView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                VStack(alignment: .leading, spacing: Constants.innerVerticalSpacing) {
                    Text(Localization.modifiedAddressInfo)
                    Text(Localization.selectAddressPrompt)
                }
                .bodyStyle()
                // TODO: Replace static data with real data from view model
                AddressView(label: Localization.enteredAddressLabel,
                            address: "15 Algonkin St, Ticonderogaa, NY 12883-1487, US",
                            isSelected: false)
                AddressView(label: Localization.suggestedAddressLabel,
                            address: "15 ALGONKIN ST, TICONDEROGA, NY 12883-1487, US",
                            isSelected: true)
            }
            .padding()
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: .zero) {
                Divider().ignoresSafeArea(edges: [.horizontal])
                Button(Localization.confirmSuggestedAddress) {
                    // TODO: Update button label based on selected address
                    // TODO: Confirm selected address
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    private struct AddressView: View {
        /// Label for the address
        let label: String

        /// Address to display, formatted in a string.
        let address: String

        /// Whether the address is selected.
        var isSelected: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: Constants.innerVerticalSpacing) {
                Text(label.localizedUppercase)
                    .footnoteStyle()
                Text(address)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(isSelected ? Color(.wooCommercePurple(.shade0)) : nil)
                    .roundedBorder(cornerRadius: 8,
                                   lineColor: isSelected ? Color(.wooCommercePurple(.shade60)) : Color(.separator),
                                   lineWidth: isSelected ? 2 : 0.5)
            }
        }
    }
}

private extension WooShippingNormalizeAddressView {
    enum Constants {
        static let verticalSpacing: CGFloat = 24
        static let innerVerticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let cancel = NSLocalizedString("wooShipping.normalizeAddress.cancel",
                                            value: "Cancel",
                                            comment: "Button to cancel normalizing an address for a Woo Shipping label")
        static let title = NSLocalizedString("wooShipping.normalizeAddress.title",
                                             value: "Confirm address",
                                             comment: "Title for the address normalization screen for a Woo Shipping label")
        static let modifiedAddressInfo = NSLocalizedString("wooShipping.normalizeAddress.modifiedAddressInfo",
                                                           value: "We have slightly modified the entered address.",
                                                           comment: "Informational text when normalizing an address for a Woo Shipping label")
        static let selectAddressPrompt = NSLocalizedString("wooShipping.normalizeAddress.selectAddressPrompt",
                                                           value: "If correct, please use the suggested address to ensure accurate delivery.",
                                                           comment: "Prompt to select the suggested address when normalizing an address for a Woo Shipping label")
        static let enteredAddressLabel = NSLocalizedString("wooShipping.normalizeAddress.enteredAddressLabel",
                                                           value: "What you entered",
                                                           comment: "Label for the address the merchant entered " +
                                                           "when normalizing an address for a Woo Shipping label")
        static let suggestedAddressLabel = NSLocalizedString("wooShipping.normalizeAddress.suggestedAddressLabel",
                                                             value: "Suggested",
                                                             comment: "Label for the suggested address when normalizing an address for a Woo Shipping label")
        static let confirmSuggestedAddress = NSLocalizedString("wooShipping.normalizeAddress.confirmSuggestedAddress",
                                                               value: "Confirm Suggested Address",
                                                               comment: "Button to confirm the suggested address for a Woo Shipping label")
        static let confirmEnteredAddress = NSLocalizedString("wooShipping.normalizeAddress.confirmEnteredAddress",
                                                             value: "Confirm Entered Address",
                                                             comment: "Button to confirm the entered address for a Woo Shipping label")
    }
}

#Preview {
    NavigationView {
        WooShippingNormalizeAddressView()
    }
    .wooNavigationBarStyle()
}
