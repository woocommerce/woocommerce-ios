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
}

/// Represent a screen with a list of IconListItems. Mainly used to present reports such as What's New in WooCommerce.
///
struct ReportList: View {
    let viewModel: ReportListPresentable
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?

    var body: some View {
        VStack {
            LargeTitle(text: viewModel.title)
                .padding(.bottom, Layout.titleBottomPadding(sizeClass))
            VStack(spacing: Layout.listSpacing(sizeClass)) {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon)
                }
            }
            .scrollVerticallyIfNeeded()
            Spacer()
            Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.buttonHorizontalPadding(sizeClass))
        }
        .onAppear(perform: viewModel.onAppear)
        .padding(.top, Layout.topPadding(sizeClass))
        .padding(.bottom, Layout.bottomPadding(sizeClass))
    }
}

private extension ReportList {
    enum Layout {

        static func topPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 75
        }

        static func bottomPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 60
        }

        static func titleBottomPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 32 : 40
        }

        static func buttonHorizontalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 24
        }

        static func listSpacing(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 24 : 32
        }
    }
}

// MARK: - Preview
struct ReportList_Previews: PreviewProvider {
    static var previews: some View {
        ReportList(viewModel: WhatsNewViewModel(items: [
            ReportItem(title: "feature 1", subtitle: "subtitle 1", icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!)),
            ReportItem(title: "feature 2", subtitle: "subtitle 2", icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!)),
            ReportItem(title: "feature 3", subtitle: "subtitle 3", icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!)),
            ReportItem(title: "feature 4", subtitle: "subtitle 4", icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))
        ], onDismiss: {}))
    }
}
