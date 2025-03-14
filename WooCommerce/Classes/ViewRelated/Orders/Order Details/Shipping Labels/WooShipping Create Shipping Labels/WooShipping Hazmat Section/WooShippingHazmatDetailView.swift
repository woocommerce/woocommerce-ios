import SwiftUI

struct WooShippingHazmatDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var isHazardous: Bool

    @State private var detailURL: URL?

    init(isHazardous: Binding<Bool>) {
        self._isHazardous = isHazardous
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.verticalSpacing) {

                    Text(Localization.title)
                        .secondaryTitleStyle()
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle(isOn: $isHazardous) {
                        Text(Localization.toggleLabel)
                    }

                    Button(Localization.selectCategory) {
                        // TODO: navigate to category list
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .renderedIf(isHazardous)

                    Divider()

                    Text(Localization.detailLine1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(detailLine2AttributedString)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(detailLine3AttributedString)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .environment(\.openURL, OpenURLAction { url in
                    detailURL = url
                    return .handled
                })
                .safariSheet(url: $detailURL)
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancel) {
                            dismiss()
                        }
                    }
                }
                .toolbarBackground(Color.clear, for: .navigationBar)
            }
        }
    }
}

private extension WooShippingHazmatDetailView {
    var detailLine2AttributedString: AttributedString {
        let content = String.localizedStringWithFormat(Localization.detailLine2, Constants.hazmatURL, Localization.searchTool)
        var attributedText = AttributedString(content)
        attributedText.font = .body
        attributedText.foregroundColor = Color(.text)

        if let range1 = attributedText.range(of: Constants.hazmatURL),
           let url = URL(string: Constants.hazmatURL) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.accentColor)
            linkContainer.underlineStyle = .single
            attributedText[range1].mergeAttributes(linkContainer)
        }

        if let range2 = attributedText.range(of: Localization.searchTool),
           let url = URL(string: Constants.searchToolURL) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.accentColor)
            linkContainer.underlineStyle = .single
            attributedText[range2].mergeAttributes(linkContainer)
        }
        return attributedText
    }

    var detailLine3AttributedString: AttributedString {
        let content = String.localizedStringWithFormat(Localization.detailLine3, Constants.DHLExpressName)

        var attributedText = AttributedString(content)
        attributedText.font = .body
        attributedText.foregroundColor = Color(.text)

        if let range = attributedText.range(of: Constants.DHLExpressName),
           let url = URL(string: Constants.DHLExpressURL) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.accentColor)
            linkContainer.underlineStyle = .single
            attributedText[range].mergeAttributes(linkContainer)
        }

        return attributedText
    }
}

private extension WooShippingHazmatDetailView {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let hazmatURL = "https://www.usps.com/hazmat"
        static let searchToolURL = "https://pe.usps.com/hazmat/index"
        static let DHLExpressName = "DHL Express"
        static let DHLExpressURL = "https://www.dhl.com/us-en/home/express.html"
    }
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingHazmatDetailView.title",
            value: "Are you shipping dangerous goods or hazardous materials?",
            comment: "Title of the HAZMAT detail view in the shipping label creation flow"
        )
        static let cancel = NSLocalizedString(
            "wooShippingHazmatDetailView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the HAZMAT detail view in the shipping label creation flow"
        )
        static let toggleLabel = NSLocalizedString(
            "wooShippingHazmatDetailView.switchLabel",
            value: "Contains hazardous materials",
            comment: "Label of the toggle on the HAZMAT detail view in the shipping label creation flow"
        )
        static let selectCategory = NSLocalizedString(
            "wooShippingHazmatDetailView.selectCategory",
            value: "Select Category",
            comment: "Button to select hazardous material category on the HAZMAT detail view in the shipping label creation flow"
        )
        static let detailLine1 = NSLocalizedString(
            "wooShippingHazmatDetailView.detailLine1",
            value: "Potentially hazardous material includes items such as batteries, dry ice, " +
            "flammable liquids, aerosols, ammunition, fireworks, nail polish, perfume, paint, solvents, " +
            "and more. Hazardous items must ship in separate packages.",
            comment: "First line of the explanation on the HAZMAT detail view in the shipping label creation flow"
        )
        static let detailLine2 = NSLocalizedString(
            "wooShippingHazmatDetailView.detailLine2",
            value: "Learn how to securely package, label, and ship HAZMAT through USPS® at " +
            "%1$@. Determine your product's mailability using the %2$@.",
            comment: "Second line of the explanation on the HAZMAT detail view in the shipping label creation flow. " +
            "The placeholders are links to detail pages for HAZMAT."
        )
        static let searchTool = NSLocalizedString(
            "wooShippingHazmatDetailView.searchTool",
            value: "USPS HAZMAT Search Tool",
            comment: "Name of the search tool linked on the HAZMAT detail view in the shipping label creation flow."
        )
        static let detailLine3 = NSLocalizedString(
            "wooShippingHazmatDetailView.detailLine3",
            value: "WooCommerce Shipping does not currently support HAZMAT shipments through %1$@.",
            comment: "Third line of the explanation on the HAZMAT detail view in the shipping label creation flow. " +
            "The placeholder is DHL Express."
        )
    }
}

#Preview {
    WooShippingHazmatDetailView(isHazardous: .constant(true))
}
