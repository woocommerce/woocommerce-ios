import Foundation
import SwiftUI

struct ApplicationPasswordTutorial: View {

    var body: some View {
        VStack(spacing: .zero) {
            ScrollView {
                Text(Localization.reason)
                    .subheadlineStyle()
                    .multilineTextAlignment(.center)
                    .padding([.bottom, .top])


                Text(Localization.tutorial)
                    .foregroundColor(Color(uiColor: .text))
                    .footnoteStyle(isEnabled: true)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)

                Image(uiImage: .appPasswordTutorialImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, Layout.imagePadding)

                Text(Localization.contactSupport)
                    .subheadlineStyle()
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.horizontal)

            Divider()
                .ignoresSafeArea()

            VStack {

                Button(Localization.continueTitle) {
                    print("Continue tapped")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.contactSupportTitle) {
                    print("Contact support tapped")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
        }
        .background(Color(uiColor: .listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ApplicationPasswordTutorial {
    enum Localization {
        static let title = NSLocalizedString("We couldn't log in into your site! 😭", comment: "Title for the application password tutorial screen")
        static let reason = NSLocalizedString("This is likely because your store has some extra security steps in place.",
                                              comment: "Reason for why the user could not login tin the application password tutorial screen")
        static let tutorial = NSLocalizedString("""
                                                ⁃ Tap the continue button at the bottom to login directly into your site.

                                                ⁃ Once logged in, approve the connection to give access to the woo app   like the in the image below.
                                                """, comment: "Tutorial steps on the application password tutorial screen")
        static let contactSupport = NSLocalizedString("If you encounter any problem, contact us and we will happily assist you!",
                                                      comment: "Text to contact support in the application password tutorial screen")
        static let continueTitle = NSLocalizedString("Continue", comment: "Continue button in the application password tutorial screen")
        static let contactSupportTitle = NSLocalizedString("Contact Support", comment: "Contact Support button in the application password tutorial screen")
    }

    enum Layout {
        static let imagePadding = 60.0
    }
}

#Preview {
    NavigationStack {
        ApplicationPasswordTutorial()
    }
}
