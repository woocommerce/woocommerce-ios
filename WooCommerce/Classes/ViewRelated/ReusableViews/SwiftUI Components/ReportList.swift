import SwiftUI
import Yosemite

protocol ReportListPresentable {
    var items: [ReportItem] { get }
    var title: String { get }
    var ctaTitle: String { get }
    var onDismiss: () -> Void { get }
}

struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconUrl: String
    let iconBase64: String?

    var icon: Icon? {
        if let base64String = iconBase64,
           let imageData = Data(base64Encoded: base64String),
           let image = UIImage(data: imageData) {
            return .base64(image)
        } else if let url = URL(string: iconUrl) {
            return .remote(url)
        }
        return nil
    }
}

/// Represent a screen with a list of IconListItems. Mainly used to present reports such as What's New in WooCommerce.
///
struct ReportList: View {
    let viewModel: ReportListPresentable
    @Environment(\.horizontalSizeClass) var sizeClass: UserInterfaceSizeClass?

    var body: some View {
        VStack {
            Spacer(minLength: Layout.topSpaceLength(sizeClass))
            LargeTitleView(text: viewModel.title)
            Spacer(minLength: Layout.listTopSpacerLength(sizeClass))
            ScrollView {
                ForEach(viewModel.items, id: \.id) {
                    IconListItem(title: $0.title,
                                 subtitle: $0.subtitle,
                                 icon: $0.icon)
                }
            }
            Spacer()
            Button(viewModel.ctaTitle, action: viewModel.onDismiss)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.buttonHorizontalPadding(sizeClass))
                .padding(.bottom, Layout.buttonVerticalPadding(sizeClass))
        }
    }
}

private extension ReportList {
    enum Layout {

        static func topSpaceLength(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 75
        }

        static func listTopSpacerLength(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 32 : 40
        }

        static func buttonHorizontalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 24
        }

        static func buttonVerticalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : 60
        }
    }
}

// MARK: - Preview
struct ReportList_Previews: PreviewProvider {
    static var previews: some View {
        ReportList(viewModel: WhatsNewViewModel(items: [
            ReportItem(title: "feature 1", subtitle: "subtitle 1", iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png", iconBase64: nil),
            ReportItem(title: "feature 2", subtitle: "subtitle 2", iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png", iconBase64: nil),
            ReportItem(title: "feature 3", subtitle: "subtitle 3", iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png", iconBase64: nil),
            ReportItem(title: "feature 4", subtitle: "subtitle 4", iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png", iconBase64: nil)
        ], onDismiss: {}))
    }
}
