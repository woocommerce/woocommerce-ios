import Foundation
import UIKit
import SwiftUI
import WordPressUI

/// Hosting Controller for the Privacy Banner View
///
final class PrivacyBannerViewController: UIHostingController<PrivacyBanner> {

    init(goToSettingsAction: @escaping (() -> ()), saveAction: @escaping (() -> ())) {
        super.init(rootView: PrivacyBanner(goToSettingsAction: goToSettingsAction, saveAction: saveAction))
    }

    /// Needed for protocol conformance.
    ///
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Needed when presented via the `BottomSheetViewController`
        preferredContentSize = .init(width: 0, height: view.intrinsicContentSize.height)
    }
}

extension PrivacyBannerViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }

    var expandedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

/// Banner View for the privacy settings.
///
struct PrivacyBanner: View {
    /// Closure to be invoked when the go to settings button is pressed.
    ///
    let goToSettingsAction: (() -> ())

    /// Closure to be invoked when the go to settings button is pressed.
    ///
    let saveAction: (() -> ())

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {

            Text(Localization.bannerTitle)
                .headlineStyle()

            Text(Localization.bannerSubtitle)
                .foregroundColor(Color(.text))
                .subheadlineStyle()

            Toggle(Localization.analytics, isOn: .constant(true))
                .tint(Color(.primary))
                .bodyStyle()
                .padding(.vertical)

            Text(Localization.toggleSubtitle)
                .subheadlineStyle()

            HStack {
                Button(Localization.goToSettings) {
                    print("Tapped Settings")
                }
                .buttonStyle(SecondaryButtonStyle())


                Button(Localization.save) {
                    print("Tapped Save")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top)

            /// Push all content to the top
            ///
            Spacer()
        }
        .padding()
    }
}

// MARK: Definitions
private extension PrivacyBanner {
    enum Localization {
        static let bannerTitle = NSLocalizedString("Manage Privacy", comment: "Title for the privacy banner")
        static let analytics = NSLocalizedString("Analytics", comment: "Title for the analytics toggle in the privacy banner")
        static let goToSettings = NSLocalizedString("Go to Settings", comment: "Title for the 'Go To Settings' button in the privacy banner")
        static let save = NSLocalizedString("Save", comment: "Title for the 'Save' button in the privacy banner")
        static let bannerSubtitle = NSLocalizedString(
            "We process your personal data to optimize our mobile apps and marketing activities based on your consent and our legitimate interest.",
            comment: "Title for the privacy banner"
        )
        static let toggleSubtitle = NSLocalizedString(
            "These cookies allow us to optimize performance by collecting information on how users interact with our mobile apps.",
            comment: "Description for the analytics toggle in the privacy banner"
        )
    }

    enum Layout {
        static let mainVerticalSpacing = CGFloat(8)
    }
}

struct PrivacyBanner_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyBanner(goToSettingsAction: {}, saveAction: {})
            .previewLayout(.sizeThatFits)
    }
}
