import SwiftUI

/// View to be displayed when the native Jetpack connection flow is dismissed.
///
struct LoginJetpackSetupInterruptedView: View {
    let onSupport: () -> Void
    let onContinue: () -> Void
    let onCancellation: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
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

                    Spacer()

                    VStack(spacing: Constants.contentVerticalSpacing) {
                        Image(uiImage: .jetpackSetupInterruptedImage)
                        Text(Localization.title)
                            .fontWeight(.semibold)
                        Text(Localization.message)
                        Text(Localization.suggestion)
                    }
                    .font(.title3)
                    .foregroundColor(Color(uiColor: .text))
                    .multilineTextAlignment(.center)

                    Spacer()

                    VStack(spacing: Constants.contentVerticalSpacing) {
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
                .frame(minHeight: geometry.size.height)
            }
        }
        .padding()
    }
}

extension LoginJetpackSetupInterruptedView {
    enum Localization {
        static let help = NSLocalizedString("Help", comment: "Button to contact support on the Jetpack setup interrupted screen")
        static let title = NSLocalizedString(
            "You interrupted the connection.",
            comment: "Title of the Jetpack setup interrupted screen"
        )
        static let message = NSLocalizedString(
            "Jetpack is installed, but not connected.",
            comment: "Message on the Jetpack setup interrupted screen"
        )
        static let suggestion = NSLocalizedString(
            "Please continue the connection process to access your store.",
            comment: "Suggestion on the Jetpack setup interrupted screen"
        )
        static let continueConnection = NSLocalizedString(
            "Continue Connection",
            comment: "Button on the Jetpack setup interrupted screen to continue the setup"
        )
        static let cancelInstallation = NSLocalizedString(
            "Cancel Installation",
            comment: "Button to cancel installation on the Jetpack setup interrupted screen"
        )
    }

    enum Constants {
        static let contentVerticalSpacing: CGFloat = 16
    }
}

struct LoginJetpackSetupInterruptedView_Previews: PreviewProvider {
    static var previews: some View {
        LoginJetpackSetupInterruptedView(onSupport: {}, onContinue: {}, onCancellation: {})
    }
}
