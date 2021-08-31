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
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    var body: some View {
        VStack {
            Spacer(minLength: Layout.topSpaceLength(verticalSizeClass, horizontalSizeClass))
            LargeTitleView(text: viewModel.title)
            Spacer(minLength: Layout.listTopSpacerLength(verticalSizeClass, horizontalSizeClass))
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
                .padding(.horizontal, Layout.buttonHorizontalPadding(verticalSizeClass, horizontalSizeClass))
                .padding(.bottom, Layout.buttonVerticalPadding(verticalSizeClass, horizontalSizeClass))
        }
    }
}

private extension ReportList {
    enum Layout {

        static func topSpaceLength(_ verticalSizeClass: UserInterfaceSizeClass?,
                                   _ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
            verticalSizeClass == .regular && horizontalSizeClass == .compact ? 40 : 75
        }

        static func listTopSpacerLength(_ verticalSizeClass: UserInterfaceSizeClass?,
                                        _ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
            verticalSizeClass == .regular && horizontalSizeClass == .compact ? 32 : 40
        }

        static func buttonHorizontalPadding(_ verticalSizeClass: UserInterfaceSizeClass?,
                                            _ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
            verticalSizeClass == .regular && horizontalSizeClass == .compact ? 40 : 24
        }

        static func buttonVerticalPadding(_ verticalSizeClass: UserInterfaceSizeClass?,
                                          _ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
            verticalSizeClass == .regular && horizontalSizeClass == .compact ? 40 : 60
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
