import SwiftUI

/// View for reviewing UPS Terms and Conditions.
struct UPSTermsView: View {

    let originAddress: String
    let onConfirmation: () -> Void

    @State private var isTOSAccepted = false
    @State private var isProhibitedItemsAccepted = false
    @State private var isTechnologyAgreementAccepted = false

    var body: some View {
        ScrollableVStack(alignment: .leading,
                         padding: Layout.contentPadding,
                         spacing: Layout.sectionSpacing) {
            Text(Localization.title)
                .font(.title3)
                .bold()

            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                Text(Localization.shippingFrom)
                    .headlineStyle()
                Text(originAddress)
                    .foregroundStyle(Color.primary)
                    .subheadlineStyle()
                Divider()
            }
            .accessibilityElement(children: .combine)

            Text(Localization.message)

            VStack(alignment: .leading, spacing: Layout.contentPadding) {
                Toggle(isOn: $isTOSAccepted) {
                    Text(checkboxContent(mainContent: Localization.checkbox1,
                                         linkText: Localization.termsOfService,
                                         link: Links.termsOfService))
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $isProhibitedItemsAccepted) {
                    Text(checkboxContent(mainContent: Localization.checkbox2,
                                         linkText: Localization.prohibitedItems,
                                         link: Links.prohibitedItems))
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $isTechnologyAgreementAccepted) {
                    Text(checkboxContent(mainContent: Localization.checkbox3,
                                         linkText: Localization.technologyAgreement,
                                         link: Links.techAgreement))
                }
                .toggleStyle(CheckboxToggleStyle())
            }

            Spacer()

            Button(Localization.confirmButton, action: onConfirmation)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isTOSAccepted ||
                          !isProhibitedItemsAccepted ||
                          !isTechnologyAgreementAccepted)
        }
        .padding(.top, Layout.contentPadding)
    }
}

private extension UPSTermsView {
    func checkboxContent(mainContent: String,
                         linkText: String,
                         link: String) -> AttributedString {
        let content = String.localizedStringWithFormat(mainContent, linkText)
        var attributedText = AttributedString(content)
        attributedText.font = .body
        attributedText.foregroundColor = Color(.text)

        if let range = attributedText.range(of: linkText),
           let url = URL(string: link) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.accentColor)
            linkContainer.underlineStyle = .single
            attributedText[range].mergeAttributes(linkContainer)
        }
        return attributedText
    }
}

private extension UPSTermsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let contentSpacing: CGFloat = 8
    }

    enum Links {
        static let termsOfService = "https://www.ups.com/assets/resources/webcontent/en_US/ups_dap_supplemental_tc.pdf"
        static let prohibitedItems = "https://www.ups.com/us/en/support/shipping-support/shipping-special-care-regulated-items/prohibited-items.page"
        static let techAgreement = "https://www.ups.com/assets/resources/webcontent/en_US/UTA.pdf"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "upsTermsView.title",
            value: "UPS® Terms and Conditions",
            comment: "Title of the UPS Terms and Conditions view"
        )
        static let shippingFrom = NSLocalizedString(
            "upsTermsView.shippingFrom",
            value: "Shipping from",
            comment: "Title label for the origin address on the UPS Terms and Conditions view"
        )
        static let message = NSLocalizedString(
            "upsTermsView.message",
            value: "To start shipping from this address with UPS®, " +
            "we need you to agree to the following terms and conditions:",
            comment: "Message on the UPS Terms and Conditions view"
        )
        static let checkbox1 = NSLocalizedString(
            "upsTermsView.checkbox1",
            value: "I agree to the %1$@.",
            comment: "The first checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the UPS Terms of Service. " +
            "Reads as: 'I agree to the UPS® Terms of Service.'"
        )
        static let checkbox2 = NSLocalizedString(
            "upsTermsView.checkbox2",
            value: "I will not ship any %1$@ that UPS® disallows, " +
            "nor any regulated items without the necessary permissions.",
            comment: "The second checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the list of prohibited items. " +
            "Reads as: 'I will not ship any Prohibited Items that UPS® disallows, " +
            "nor any regulated items without the necessary permissions.'"
        )
        static let checkbox3 = NSLocalizedString(
            "upsTermsView.checkbox3",
            value: "I also agree to the %1$@.",
            comment: "The third checkbox on the UPS Terms and Conditions view. " +
            "The placeholder is a link to the UPS Technology Agreement. " +
            "Reads as: 'I also agree to the UPS® Technology Agreement.'"
        )
        static let termsOfService = NSLocalizedString(
            "upsTermsView.termsOfService",
            value: "UPS® Terms of Service",
            comment: "Link to the terms of service on the UPS Terms and Conditions view"
        )
        static let prohibitedItems = NSLocalizedString(
            "upsTermsView.prohibitedItems",
            value: "Prohibited Items",
            comment: "Link to the prohibited items on the UPS Terms and Conditions view"
        )
        static let technologyAgreement = NSLocalizedString(
            "upsTermsView.technologyAgreement",
            value: "UPS® Technology Agreement",
            comment: "Link to the technology agreement on the UPS Terms and Conditions view"
        )
        static let confirmButton = NSLocalizedString(
            "upsTermsView.confirmButton",
            value: "Confirm and continue",
            comment: "Button to confirm all agreements on the UPS Terms and Conditions view"
        )
    }
}

#Preview {
    UPSTermsView(originAddress: "3028 24TH ST, SAN FRANCISCO, CA 94110-4129, US",
                 onConfirmation: {})
}
