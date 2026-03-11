import SwiftUI
import Yosemite

protocol ReportListPresentable {
    var items: [ReportItem] { get }
    var title: String { get }
    var ctaTitle: String { get }
    var learnMoreURL: URL? { get }
    var onDismiss: () -> Void { get }
    func onAppear()
}

struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: IconListItem.Icon?
}

/// Represent a screen with a list of IconListItems. Mainly used to present reports such as What's New in WooCommerce.
///
struct ReportList: View {
    let viewModel: ReportListPresentable
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            LargeTitle(text: viewModel.title)
                .padding(.bottom, Layout.titleBottomPadding(sizeClass))
                .padding(.top, Layout.topPadding(sizeClass))
            VStack(spacing: Layout.listSpacing(sizeClass)) {
                ForEach(viewModel.items, id: \.id) { item in
                    IconListItem(title: item.title,
                                 subtitle: item.subtitle,
                                 icon: item.icon)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .safeAreaInset(edge: .bottom) {
            VStack {
                if let learnMoreURL = viewModel.learnMoreURL {
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
            "reportList.learnMore.link",
            value: "Learn more",
            comment: "Primary learn more button in the What's New screen"
        )
        static let dismiss = NSLocalizedString(
            "reportList.notNow.button",
            value: "Not now",
            comment: "Secondary not now button in the What's New screen"
        )
    }
}

// MARK: - Preview
struct ReportList_Previews: PreviewProvider {
    static let sampleIconURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!
    static let sampleLearnMoreURL = URL(string: "https://woocommerce.com/learn-more")!

    static var previews: some View {
        ReportList(viewModel: WhatsNewViewModel(items: [
            ReportItem(
                title: "feature 1",
                subtitle: "subtitle 1",
                icon: .remote(sampleIconURL)
            ),
            ReportItem(
                title: "feature 2",
                subtitle: "subtitle 2",
                icon: .remote(sampleIconURL)
            ),
            ReportItem(
                title: "feature 3",
                subtitle: "subtitle 3",
                icon: .remote(sampleIconURL)
            )
        ], onDismiss: {}))
        .previewDisplayName("Without Learn More URL")

        ReportList(viewModel: WhatsNewViewModel(items: [
            ReportItem(
                title: "Point of Sale",
                subtitle: "Sell in person with the new Point of Sale feature.",
                icon: .remote(sampleIconURL)
            ),
            ReportItem(
                title: "Improved Analytics",
                subtitle: "Track your store performance with enhanced analytics.",
                icon: .remote(sampleIconURL)
            )
        ], learnMoreURL: sampleLearnMoreURL, onDismiss: {}))
        .previewDisplayName("With Learn More URL")
    }
}
