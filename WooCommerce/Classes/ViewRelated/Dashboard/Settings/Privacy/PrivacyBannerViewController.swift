import Foundation
import UIKit
import SwiftUI
import WordPressUI

/// Hosting Controller for the Privacy Banner View
///
final class PrivacyBannerViewController: UIHostingController<PrivacyBanner> {

    /// Tracks the banner view intrinsic height.
    /// Needed to enable it's scrolling when it grows bigger than the screen.
    ///
    var bannerIntrinsicHeight: CGFloat = 0

    init(goToSettingsAction: @escaping (() -> ()), saveAction: @escaping (() -> ())) {
        let viewModel = PrivacyBannerViewModel()
        super.init(rootView: PrivacyBanner(goToSettingsAction: goToSettingsAction, saveAction: saveAction, viewModel: viewModel))
    }

    /// Needed for protocol conformance.
    ///
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make the banner scrollable when the banner height is bigger than the screen height.
        // Send it in the next run loop to avoid a recursive `viewDidLayoutSubviews`.
        bannerIntrinsicHeight = view.intrinsicContentSize.height
        DispatchQueue.main.async {
            self.rootView.shouldScroll = self.bannerIntrinsicHeight > self.view.frame.height
        }
    }
}

extension PrivacyBannerViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(bannerIntrinsicHeight)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(bannerIntrinsicHeight)
    }
}

/// Banner View for the privacy settings.
///
struct PrivacyBanner: View {
    /// Closure to be invoked when the go to settings button is pressed.
    ///
    let goToSettingsAction: (() -> ())

    /// Closure to be invoked when the save button is pressed.
    ///
    let saveAction: (() -> ())

    /// Determines in the banner should be scrollable on it's parent container.
    ///
    var shouldScroll: Bool = false

    /// Main View Model.
    ///
    @StateObject var viewModel: PrivacyBannerViewModel

    var body: some View {
        if shouldScroll {
            ScrollView(showsIndicators: false) {
                banner
            }
        } else {
            banner
        }
    }

    var banner: some View {
        VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {

            Text(Localization.bannerTitle)
                .headlineStyle()

            Text(Localization.bannerSubtitle)
                .foregroundColor(Color(.text))
                .subheadlineStyle()

            Toggle(Localization.analytics, isOn: $viewModel.analyticsEnabled)
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
            "privacy_banner_subtitle",
            value: "Your privacy is critically important to us and always has been. We use, store, and process your personal data to optimize our app " +
            "(and your experience) in various ways. Some uses of your data we absolutely need in order to make things work, and others you can " +
            "customize from your Settings.",
            comment: "Subtitle for the privacy banner"
        )
        static let toggleSubtitle = NSLocalizedString(
            "Allow us to optimize performance by collecting information on how users interact with our mobile apps.",
            comment: "Description for the analytics toggle in the privacy banner"
        )
    }

    enum Layout {
        static let mainVerticalSpacing = CGFloat(8)
    }
}

struct PrivacyBanner_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyBanner(goToSettingsAction: {}, saveAction: {}, viewModel: .init())
            .previewLayout(.sizeThatFits)
    }
}
