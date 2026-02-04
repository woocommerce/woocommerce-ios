import SwiftUI
import struct WooFoundation.ScrollableVStack

/// View for reviewing UPS Terms and Conditions.
struct UPSTermsView: View {

    @ObservedObject var viewModel: UPSTermsViewModel

    let onConfirmation: () -> Void

    @State private var didFailToConfirmAcceptance = false

    @State private var externalURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            ScrollableVStack(alignment: .leading,
                             padding: Layout.contentPadding,
                             spacing: Layout.sectionSpacing) {
                Text(Localization.title)
                    .font(.title3)
                    .bold()

                VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                    Text(Localization.shippingFrom)
                        .headlineStyle()
                    Text(viewModel.displayedOriginAddress)
                        .foregroundStyle(Color.primary)
                        .subheadlineStyle()
                    Divider()
                }
                .accessibilityElement(children: .combine)

                Text(Localization.message)

                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    Toggle(isOn: $viewModel.isTOSAccepted) {
                        Text(
                            AttributedString.withEmbeddedLink(
                                mainContent: Localization.checkbox1,
                                linkText: Localization.termsOfService,
                                link: Links.termsOfService
                            )
                        )
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    Toggle(isOn: $viewModel.isProhibitedItemsAccepted) {
                        Text(
                            AttributedString.withEmbeddedLink(
                                mainContent: Localization.checkbox2,
                                linkText: Localization.prohibitedItems,
                                link: Links.prohibitedItems
                            )
                        )
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    Toggle(isOn: $viewModel.isTechnologyAgreementAccepted) {
                        Text(
                            AttributedString.withEmbeddedLink(
                                mainContent: Localization.checkbox3,
                                linkText: Localization.technologyAgreement,
                                link: Links.techAgreement
                            )
                        )
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }

                Spacer()
            }

            VStack(spacing: 0) {
                Divider()

                Button(Localization.confirmButton, action: {
                    Task { @MainActor in
                        await confirmAcceptance()
                    }
                })
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isConfirming))
                .padding(Layout.contentPadding)
                .disabled(!viewModel.shouldEnableConfirmButton)
            }
        }
        .padding(.top, Layout.contentPadding)
        .alert(Localization.errorTitle, isPresented: $didFailToConfirmAcceptance) {
            Button(Localization.retry) {
                Task { @MainActor in
                    await confirmAcceptance()
                }
            }
            Button(Localization.cancel, role: .cancel) {}
        } message: {
            Text(Localization.errorMessage)
        }
        .environment(\.openURL, OpenURLAction { url in
            externalURL = url
            return .handled
        })
        .safariSheet(url: $externalURL)
    }
}

private extension UPSTermsView {
    @MainActor
    func confirmAcceptance() async {
        do {
            let result = try await viewModel.confirmAcceptance()
            if result {
                onConfirmation()
            } else {
                didFailToConfirmAcceptance = true
            }
        } catch {
            DDLogError("⛔️ Error accepting UPS terms of service \(error)")
            didFailToConfirmAcceptance = true
        }
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
        static let errorTitle = NSLocalizedString(
            "upsTermsView.errorTitle",
            value: "Error confirming acceptance",
            comment: "Title of the alert when confirming all agreements on the UPS Terms and Conditions view fails"
        )
        static let errorMessage = NSLocalizedString(
            "upsTermsView.errorMessage",
            value: "An unexpected error occurred when confirming your acceptance. Please try again.",
            comment: "Title of the alert when confirming all agreements on the UPS Terms and Conditions view fails"
        )
        static let retry = NSLocalizedString(
            "upsTermsView.retry",
            value: "Retry",
            comment: "Button to retry confirming all agreements on the UPS Terms and Conditions view fails"
        )
        static let cancel = NSLocalizedString(
            "upsTermsView.cancel",
            value: "Cancel",
            comment: "Button to cancel confirming all agreements on the UPS Terms and Conditions view fails"
        )
    }
}

#Preview {
    UPSTermsView(viewModel: UPSTermsViewModel(siteID: 123,
                                              originAddress: .init(company: "A8C",
                                                                   name: "John Doe",
                                                                   email: "test@mail.com",
                                                                   phone: "09381734543",
                                                                   country: "US",
                                                                   state: "New York",
                                                                   address1: "1 E 35th St",
                                                                   address2: "",
                                                                   city: "New York",
                                                                   postcode: "10028")),
                 onConfirmation: {})
}
