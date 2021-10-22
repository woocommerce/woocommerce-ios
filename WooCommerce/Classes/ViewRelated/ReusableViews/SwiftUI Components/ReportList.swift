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
                .padding(.top, Layout.titleTopPadding(sizeClass))
                .padding(.bottom, Layout.listVerticalPadding(sizeClass))
            VStack(spacing: Layout.listSpacing) {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon)
                }
            }
            .scrollVerticallyIfNeeded()
            Spacer(minLength: Layout.listVerticalPadding(sizeClass))
            Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                .buttonStyle(PrimaryButtonStyle())
        }
        .onAppear(perform: viewModel.onAppear)
        .padding(Layout.padding)
    }
}

private extension ReportList {
    enum Layout {

        static func titleTopPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 0 : 35
        }

        static func listVerticalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 32 : 40
        }

        static let padding: CGFloat = 40
        static let listSpacing: CGFloat = 32
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
