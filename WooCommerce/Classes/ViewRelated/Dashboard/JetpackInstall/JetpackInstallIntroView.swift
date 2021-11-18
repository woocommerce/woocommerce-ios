import SwiftUI

struct JetpackInstallIntroView: View {
    // Closure invoked when Close button is tapped
    var dismissAction: () -> Void = {}

    /// Closure invoked when the install button is tapped
    ///
    var installAction: () -> Void = {}

    var body: some View {
        VStack {
            HStack {
                Button(Localization.closeButton, action: dismissAction)
                .buttonStyle(LinkButtonStyle())
                .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }

            Spacer()

            VStack {
                Image(uiImage: .jetpackLogoImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(.jetpackGreen))
                    .frame(width: Constants.jetpackLogoSize, height: Constants.jetpackLogoSize)
            }

            Spacer()

            // Primary Button to install Jetpack
            Button(Localization.installAction, action: installAction)
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Constants.horizontalMargin)
                .padding(.bottom, Constants.installJetpackBottomMargin)
        }
    }
}

private extension JetpackInstallIntroView {
    enum Constants {
        static let jetpackLogoSize: CGFloat = 120
        static let horizontalMargin: CGFloat = 16
        static let installJetpackBottomMargin: CGFloat = 28
    }

    enum Localization {
        static let closeButton = NSLocalizedString("Close", comment: "Title of the Close action on the Jetpack Install view")
        static let installAction = NSLocalizedString("Install Jetpack", comment: "Title of install action in the Jetpack benefits view.")
    }
}

struct JetpackInstallIntroView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallIntroView()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))

        JetpackInstallIntroView()
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 800, height: 300))
    }
}
