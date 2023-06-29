import SwiftUI

struct UpgradeWaitingView: View {
    let planName: String

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                ProgressView()
                    .progressViewStyle(IndefiniteCircularProgressViewStyle(size: Layout.progressIndicatorSize,
                                                                           lineWidth: Layout.progressIndicatorLineWidth))
                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    Text(Localization.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: Localization.descriptionFormatString, planName))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)

            Spacer()
        }
    }
}

private extension UpgradeWaitingView {
    enum Localization {
        static let title = NSLocalizedString("You’re almost there",
                                             comment: "Title for the progress screen shown after an In-App Purchase " +
                                             "for a Woo Express plan, while we upgrade the site.")

        static let descriptionFormatString = NSLocalizedString(
            "Please bear with us while we process the payment for your %1$@ plan.",
            comment: "Detail text shown after an In-App Purchase for a Woo Express plan, shown while we upgrade the " +
            "site. %1$@ is replaced with the short plan name. " +
            "Reads as: 'Please bear with us while we process the payment for your Essential plan.'")
    }

    enum Layout {
        static let progressIndicatorSize: CGFloat = 56
        static let progressIndicatorLineWidth: CGFloat = 6
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 152
        static let spacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
    }
}
