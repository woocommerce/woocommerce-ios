import SwiftUI

/// Hosting controller for `WooPaymentSetupCelebrationView`.
///
final class WooPaymentSetupCelebrationHostingController: UIHostingController<WooPaymentSetupCelebrationView> {
    init(onTappingDone: @escaping () -> Void) {
        super.init(rootView: WooPaymentSetupCelebrationView(onTappingDone: onTappingDone))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Celebration view presented after Woo Payment setup
struct WooPaymentSetupCelebrationView: View {
    private let onTappingDone: () -> Void

    init(onTappingDone: @escaping () -> Void) {
        self.onTappingDone = onTappingDone
    }

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Image(uiImage: .checkSuccessImage)

            Group {
                Text(Localization.title)
                    .headlineStyle()
                    .multilineTextAlignment(.center)

                Text(Localization.subtitle)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Layout.textHorizontalPadding)

            Button(Localization.done) {
                onTappingDone()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.buttonHorizontalPadding)
        }
        .padding(insets: Layout.insets)
    }
}

private extension WooPaymentSetupCelebrationView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 24
        static let buttonHorizontalPadding: CGFloat = 16
        static let insets: EdgeInsets = .init(top: 40, leading: 0, bottom: 16, trailing: 0)
    }

    enum Localization {
        static let title = NSLocalizedString("You did it!",
                                                  comment: "Title in Woo Payments setup celebration screen.")

        static let subtitle = NSLocalizedString("Congratulations! You've successfully navigated through the setup and your payment system is ready to roll.",
                                                    comment: "Subtitle in Woo Payments setup  celebration screen.")

        static let done = NSLocalizedString("Done",
                                             comment: "Dismiss button title in Woo Payments setup celebration screen.")
    }
}

struct WooPaymentSetupCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        WooPaymentSetupCelebrationView(onTappingDone: {})

        WooPaymentSetupCelebrationView(onTappingDone: {})
            .preferredColorScheme(.dark)
    }
}
