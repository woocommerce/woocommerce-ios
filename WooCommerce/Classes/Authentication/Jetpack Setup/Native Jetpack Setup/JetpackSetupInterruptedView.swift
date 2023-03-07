import SwiftUI

/// View to be displayed when the Jetpack connection flow is dismissed.
/// This screen is used only in the Jetpack setup flow for non-JCP sites.
///
struct JetpackSetupInterruptedView: View {
    let siteURL: String
    let onSupport: () -> Void
    let onContinue: () -> Void
    let onCancellation: () -> Void

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onSupport()
                } label: {
                    Text(Localization.help)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(uiColor: .accent))
            }
            .padding(.trailing, Constants.contentSpacing)
            .padding(.top, Constants.contentSpacing)

            ScrollableVStack(padding: Constants.contentSpacing, spacing: Constants.contentSpacing) {
                Spacer()

                VStack(spacing: Constants.contentSpacing) {
                    // Error image
                    Image(uiImage: .jetpackSetupInterruptedImage)

                    // Site address info
                    HStack(spacing: Constants.contentSpacing) {
                        AsyncImage(url: URL(string: siteURL + Constants.favicoPath)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "globe.americas.fill").resizable()
                        }
                        .frame(width: Constants.faviconSize * scale, height: Constants.faviconSize * scale)
                        .scaledToFit()

                        Text(siteURL.trimHTTPScheme())
                            .bodyStyle()
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(uiColor: .text))
                    .padding(Constants.contentSpacing)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    }
                    .padding(.bottom, Constants.contentSpacing)

                    // Error title
                    Text(Localization.title)
                        .fontWeight(.semibold)

                    // Error message
                    Text(Localization.message)
                }
                .font(.title3)
                .foregroundColor(Color(uiColor: .text))
                .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: Constants.contentSpacing) {
                    Button {
                        onContinue()
                    } label: {
                        Text(Localization.continueConnection)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        onCancellation()
                    } label: {
                        Text(Localization.cancelInstallation)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }
}

extension JetpackSetupInterruptedView {
    enum Localization {
        static let help = NSLocalizedString("Help", comment: "Button to contact support on the Jetpack setup interrupted screen")
        static let title = NSLocalizedString(
            "Jetpack is installed, but not connected.",
            comment: "Title of the Jetpack setup interrupted screen"
        )
        static let message = NSLocalizedString(
            "Try connecting again to access your store.",
            comment: "Message on the Jetpack setup interrupted screen"
        )
        static let continueConnection = NSLocalizedString(
            "Connect Jetpack",
            comment: "Button on the Jetpack setup interrupted screen to continue the setup"
        )
        static let cancelInstallation = NSLocalizedString(
            "Exit Without Connecting",
            comment: "Button to cancel installation on the Jetpack setup interrupted screen"
        )
    }

    enum Constants {
        static let contentSpacing: CGFloat = 16
        static let faviconSize: CGFloat = 20
        static let favicoPath = "/favicon.ico"
    }
}

struct JetpackSetupInterruptedView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackSetupInterruptedView(siteURL: "this-is-a-really-really-long-long-long-store-address.com", onSupport: {}, onContinue: {}, onCancellation: {})
        JetpackSetupInterruptedView(siteURL: "this-is-an-address.com", onSupport: {}, onContinue: {}, onCancellation: {})
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
