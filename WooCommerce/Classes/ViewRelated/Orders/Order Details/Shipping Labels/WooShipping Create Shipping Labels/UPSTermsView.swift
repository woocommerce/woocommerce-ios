import SwiftUI

/// View for reviewing UPS Terms and Conditions.
struct UPSTermsView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

private extension UPSTermsView {
    enum Localization {
        static let title = NSLocalizedString(
            "upsTermsView.title",
            value: "UPS® Terms and Conditions",
            comment: "Title of the UPS Terms and Conditions alert"
        )
        static let shippingFrom = NSLocalizedString(
            "upsTermsView.shippingFrom",
            value: "Shipping from",
            comment: "Title label for the origin address on the UPS Terms and Conditions alert"
        )
        static let message = NSLocalizedString(
            "upsTermsView.message",
            value: "To start shipping from this address with UPS®, " +
            "we need you to agree to the following terms and conditions:",
            comment: "Message on the UPS Terms and Conditions alert"
        )
        static let checkbox1 = NSLocalizedString(
            "upsTermsView.checkbox1",
            value: "I agree to the %1$@.",
            comment: "The first checkbox on the UPS Terms and Conditions alert. " +
            "The placeholder is a link to the UPS Terms of Service. " +
            "Reads as: 'I agree to the UPS® Terms of Service.'"
        )
        static let checkbox2 = NSLocalizedString(
            "upsTermsView.checkbox2",
            value: "I will not ship any %1$@ that UPS® disallows, " +
            "nor any regulated items without the necessary permissions.",
            comment: "The second checkbox on the UPS Terms and Conditions alert. " +
            "The placeholder is a link to the list of prohibited items. " +
            "Reads as: 'I will not ship any Prohibited Items that UPS® disallows, " +
            "nor any regulated items without the necessary permissions.'"
        )
        static let checkbox3 = NSLocalizedString(
            "upsTermsView.checkbox3",
            value: "I also agree to the %1$@.",
            comment: "The third checkbox on the UPS Terms and Conditions alert. " +
            "The placeholder is a link to the UPS Technology Agreement. " +
            "Reads as: 'I also agree to the UPS® Technology Agreement.'"
        )
        static let termsOfService = NSLocalizedString(
            "upsTermsView.termsOfService",
            value: "UPS® Terms of Service",
            comment: "Link to the terms of service on the UPS Terms and Conditions alert"
        )
        static let prohibitedItems = NSLocalizedString(
            "upsTermsView.prohibitedItems",
            value: "Prohibited Items",
            comment: "Link to the prohibited items on the UPS Terms and Conditions alert"
        )
        static let technologyAgreement = NSLocalizedString(
            "upsTermsView.technologyAgreement",
            value: "UPS® Technology Agreement",
            comment: "Link to the technology agreement on the UPS Terms and Conditions alert"
        )
    }
}

#Preview {
    UPSTermsView()
}
