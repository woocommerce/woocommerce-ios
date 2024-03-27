import Foundation
import SwiftUI

/// Application Password Tutorial Hosting Controller
///
final class ApplicationPasswordTutorialViewController: UIHostingController<ApplicationPasswordTutorial> {

    /// Assign it to react when the continue button is tapped.
    ///
    var continueButtonTapped: (() -> ())? {
        get {
            rootView.continueButtonTapped
        }
        set {
            rootView.continueButtonTapped = newValue
        }
    }

    /// Assign it to react when the contact support button is tapped.
    ///
    var contactSupportButtonTapped: (() -> ())? {
        get {
            rootView.contactSupportButtonTapped
        }
        set {
            rootView.contactSupportButtonTapped = newValue
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent {
            ServiceLocator.analytics.track(event: .ApplicationPasswordAuthorization.explanationDismissed())
        }
    }

    init(error: Error) {
        let view = ApplicationPasswordTutorial(errorDescription: ApplicationPasswordTutorialViewModel.friendlyErrorMessage(for: error))
        super.init(rootView: view)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// App Passwords tutorial view.
///
struct ApplicationPasswordTutorial: View {

    /// Assign it to react when the continue button is tapped.
    ///
    var continueButtonTapped: (() -> ())?

    /// Assign it to react when the contact support button is tapped.
    ///
    var contactSupportButtonTapped: (() -> ())?

    /// Friendly error description.
    ///
    let errorDescription: String

    var body: some View {
        VStack(spacing: .zero) {
            ScrollView {
                Text(errorDescription)
                    .subheadlineStyle()
                    .multilineTextAlignment(.leading)
                    .padding([.bottom, .top])

                Divider()

                Text(Localization.tutorial)
                    .foregroundColor(Color(uiColor: .text))
                    .footnoteStyle(isEnabled: true)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)

                Image(uiImage: .appPasswordTutorialImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, Layout.imagePadding)

                Text(Localization.tutorial2)
                    .foregroundColor(Color(uiColor: .text))
                    .footnoteStyle(isEnabled: true)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)

                Divider()

                Text(Localization.contactSupport)
                    .subheadlineStyle()
                    .multilineTextAlignment(.leading)
                    .padding()
            }
            .padding(.horizontal)

            Divider()
                .ignoresSafeArea()

            VStack {

                Button(Localization.continueTitle) {
                    continueButtonTapped?()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(Localization.contactSupportTitle) {
                    contactSupportButtonTapped?()
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
        static let title = NSLocalizedString("We couldn’t log in into your store", comment: "Title for the application password tutorial screen")
        static let reason = NSLocalizedString("This could be because your store has some extra security steps in place.",
                                              comment: "Reason for why the user could not login tin the application password tutorial screen")
        static let tutorial = NSLocalizedString("""
                                                Follow these steps to connect the Woo app directly to your store using an application password.

                                                1. First, log in using your site credentials.

                                                2. When prompted, approve the connection by tapping the confirmation button.
                                                """, comment: "Tutorial steps on the application password tutorial screen")
        static let tutorial2 = NSLocalizedString("""
                                                3. When the connection is complete, you will be logged in to your store.
                                                """, comment: "Tutorial steps on the application password tutorial screen")
        static let contactSupport = NSLocalizedString("If you run into any issues, please contact our support team.",
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
        ApplicationPasswordTutorial(errorDescription: ApplicationPasswordTutorial.Localization.reason)
    }
}
