import SwiftUI
import Yosemite

protocol ReportListPresentable {
    var items: [ReportItem] { get }
    var title: String { get }
    var ctaTitle: String { get }
    var onDismiss: () -> Void { get }
    func onAppear()
}

struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: IconListItem.Icon?
    let learnMoreURL: URL?
}

/// Represent a screen with a list of IconListItems. Mainly used to present reports such as What's New in WooCommerce.
///
struct ReportList: View {
    let viewModel: ReportListPresentable
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?
    @Environment(\.openURL) private var openURL

    private var singleItemLearnMoreURL: URL? {
        guard viewModel.items.count == 1 else { return nil }
        return viewModel.items.first?.learnMoreURL
    }

    private var shouldShowBottomLearnMore: Bool {
        singleItemLearnMoreURL != nil
    }

    var body: some View {
        ScrollView {
            LargeTitle(text: viewModel.title)
                .padding(.bottom, Layout.titleBottomPadding(sizeClass))
                .padding(.top, Layout.topPadding(sizeClass))
            VStack(spacing: Layout.listSpacing(sizeClass)) {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon,
                                 learnMoreURL: $0.learnMoreURL,
                                 showLearnMoreInline: !shouldShowBottomLearnMore)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .safeAreaInset(edge: .bottom) {
            VStack {
                if let learnMoreURL = singleItemLearnMoreURL {
                    Button(Localization.learnMore) {
                        openURL(learnMoreURL)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button(Localization.dismiss, action: viewModel.onDismiss)
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

private extension ReportList {
    enum Layout {

        static func topPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 75
        }

        static func titleBottomPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 32 : 40
        }

        static func listSpacing(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 24 : 32
        }
    }

    enum Localization {
        static let learnMore = NSLocalizedString(
            "learnMore.link",
            value: "Learn more",
            comment: "Primary learn more button in the What's New screen"
        )
        static let dismiss = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.notNowButton",
            value: "Not now",
            comment: "Secondary not now button in the What's New screen"
        )
    }
}

// MARK: - Preview
struct ReportList_Previews: PreviewProvider {
    static var previews: some View {
        ReportList(viewModel: WhatsNewViewModel(items: [
            ReportItem(
                title: "feature 1",
                subtitle: "subtitle 1",
                icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!),
                learnMoreURL: nil
            ),
            ReportItem(
                title: "feature 2",
                subtitle: "subtitle 2",
                icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!),
                learnMoreURL: nil
            ),
            ReportItem(
                title: "feature 3",
                subtitle: "subtitle 3",
                icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!),
                learnMoreURL: nil
            ),
            ReportItem(
                title: "feature 4",
                subtitle: "subtitle 4",
                icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!),
                learnMoreURL: nil
            )
        ], onDismiss: {}))
    }
}
