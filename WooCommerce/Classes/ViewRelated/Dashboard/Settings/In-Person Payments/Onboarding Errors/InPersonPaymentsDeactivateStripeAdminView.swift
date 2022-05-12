import SwiftUI

struct InPersonPaymentsDeactivateStripeAdmin: View {
    let countryCode: String

    let onRefresh: () -> Void
    @State var presentedSetupURL: URL? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingError.MainContent(
                title: title,
                message: Localization.message,
                image: InPersonPaymentsOnboardingError.ImageInfo(
                    image: .paymentErrorImage,
                    height: 108.0
                ),
                supportLink: false
            )

            InPersonPaymentsSupportLink()

            Spacer()

            Button {
                presentedSetupURL = setupURL
            } label: {
                HStack {
                    Text(Localization.primaryButton)
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, Constants.padding)

            InPersonPaymentsLearnMore()
        }
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
    }

    var title: String {
        guard let countryName = Locale.current.localizedString(forRegionCode: countryCode) else {
            DDLogError("In-Person Payments unsupported in country code \(countryCode), which can't be localized")
            return Localization.titleUnknownCountry
        }
        return String(format: Localization.title, countryName)
    }

    var setupURL: URL? {
        guard let adminURL = ServiceLocator.stores.sessionManager.defaultSite?.adminURL else {
            return nil
        }

        return URL(string: adminURL)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "We don’t support In-Person Payments with Stripe in %1$@",
        comment: "Title for the error screen when there is more than one plugin active that supports in-person payments."
    )

    static let titleUnknownCountry = NSLocalizedString(
        "We don’t support In-Person Payments in your country",
        comment: "Title for the error screen when In-Person Payments is not supported because we don't know the name of the country"
    )

    static let message = NSLocalizedString(
        "In-Person Payments will only work with WCPay activated. Please deactivate Stripe to continue.",
        comment: "Message prompting an administrator to deactivate one of two plugins"
    )

    static let primaryButton = NSLocalizedString(
        "Manage Plugins",
        comment: "Button to open browser to manage plugins"
    )
}

private enum Constants {
    static let height: CGFloat = 108.0
    static let padding: CGFloat = 24.0
}

struct InPersonPaymentsDeactivateStripeAdmin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginConflictAdmin(onRefresh: {})
    }
}
