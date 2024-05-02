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
        ScrollView {
            LargeTitle(text: viewModel.title)
                .padding(.bottom, Layout.titleBottomPadding(sizeClass))
                .padding(.top, Layout.topPadding(sizeClass))
            VStack(spacing: Layout.listSpacing(sizeClass)) {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
            }
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
