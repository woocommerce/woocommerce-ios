import SwiftUI

/// Hosting controller wrapper for `StorePickerError`
///
final class StorePickerErrorHostingController: UIHostingController<StorePickerError> {
    init(troubleshootingAction: @escaping () -> Void, contactSupportAction: @escaping () -> Void, dismissAction: @escaping () -> Void) {
        super.init(rootView: StorePickerError(troubleshootingAction: troubleshootingAction,
                                              contactSupportAction: contactSupportAction,
                                              dismissAction: dismissAction))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// Generic Store Picker error view that allows the user to contact support.
///
struct StorePickerError: View {

    /// Closure invoked when the "Troubleshooting" button is pressed
    ///
    let troubleshootingAction: () -> Void

    /// Closure invoked when the "Contact Support" button is pressed
    ///
    let contactSupportAction: () -> Void

    /// Closure invoked when the "Back To Sites" button is pressed
    ///
    let dismissAction: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {
            // Title
            Text(Localization.title)
                .headlineStyle()

            // Main image
            Image(uiImage: .errorImage)

            // Body text
            Text(Localization.body)
                .multilineTextAlignment(.center)
                .bodyStyle()

            VStack(spacing: Layout.buttonsSpacing) {
                // Primary Button
                Button(Localization.troubleshoot, action: troubleshootingAction)
                    .buttonStyle(PrimaryButtonStyle())

                // Secondary button
                Button(Localization.contact, action: contactSupportAction)
                    .buttonStyle(SecondaryButtonStyle())

                // Dismiss button
                Button(Localization.back, action: dismissAction)
                    .buttonStyle(LinkButtonStyle())
            }
        }
        .padding([.leading, .trailing, .bottom])
        .padding(.top, Layout.topPadding)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(Layout.rounderCorners)
    }
}

// MARK: Constant

private extension StorePickerError {
    enum Localization {
        static let title = NSLocalizedString("We couldn't load your site", comment: "Title for the default store picker error screen")
        static let body = NSLocalizedString("Please try again or reach out to us and we'll be happy to assist you!",
                                            comment: "Body text for the default store picker error screen")
        static let troubleshoot = NSLocalizedString("Read our Troubleshooting Tips",
                                                    comment: "Text for the button to navigate to troubleshooting tips from the store picker error screen")
        static let contact = NSLocalizedString("Contact Support",
                                               comment: "Text for the button to contact support from the store picker error screen")
        static let back = NSLocalizedString("Back to Sites",
                                            comment: "Text for the button to dismiss the store picker error screen")
    }

    enum Layout {
        static let rounderCorners: CGFloat = 10
        static let mainVerticalSpacing: CGFloat = 25
        static let buttonsSpacing: CGFloat = 15
        static let topPadding: CGFloat = 30
    }
}

// MARK: Previews

struct StorePickerError_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            StorePickerError(troubleshootingAction: {}, contactSupportAction: {}, dismissAction: {})
        }
        .padding()
        .background(Color.gray)
        .previewLayout(.sizeThatFits)

        VStack {
            StorePickerError(troubleshootingAction: {}, contactSupportAction: {}, dismissAction: {})
        }
        .padding()
        .background(Color.gray)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
}
