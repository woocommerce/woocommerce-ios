import SwiftUI

struct CompletedUpgradeView: View {
    // Confetti animation runs on any change of this variable
    @State private var confettiTrigger: Int = 0

    let planName: String

    let doneAction: (() -> Void)

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(spacing: Layout.groupSpacing) {
                    Image("plan-upgrade-success-celebration")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityHidden(true)

                    VStack(spacing: Layout.textSpacing) {
                        Text(Localization.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(LocalizedString(format: Localization.subtitle, planName))
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(Localization.hint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Layout.completedUpgradeViewTopPadding)
                .padding(.horizontal, Layout.padding)
            }

            Spacer()

            Button(Localization.doneButtonText) {
                doneAction()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.padding)
        }
        .confettiCannon(counter: $confettiTrigger,
                        num: Constants.numberOfConfettiElements,
                        colors: [.withColorStudio(name: .wooCommercePurple, shade: .shade10),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade30),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade70),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade80)],
                        radius: Constants.confettiRadius)
        .onAppear {
            confettiTrigger += 1
        }
        .padding(.bottom, Layout.padding)
    }
}

private extension CompletedUpgradeView {
    struct Layout {
        static let completedUpgradeViewTopPadding: CGFloat = 70
        static let padding: CGFloat = 16
        static let groupSpacing: CGFloat = 32
        static let textSpacing: CGFloat = 16
    }

    struct Constants {
        static let numberOfConfettiElements: Int = 100
        static let confettiRadius: CGFloat = 500
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Woo! You’re off to a great start!",
            comment: "Text shown when a plan upgrade has been successfully purchased.")

        static let subtitle = NSLocalizedString(
            "Your purchase is complete and you're on the %1$@ plan.",
            comment: "Additional text shown when a plan upgrade has been successfully purchased. %1$@ is replaced by " +
            "the plan name, and should be included in the translated string.")

        static let hint = NSLocalizedString(
            "You can manage your subscription in your iPhone Settings → Your Name → Subscriptions",
            comment: "Instructions guiding the merchant to manage a site's plan upgrade.")

        static let doneButtonText = NSLocalizedString(
            "Done",
            comment: "Done button on the screen that is shown after a successful plan upgrade.")
    }
}
