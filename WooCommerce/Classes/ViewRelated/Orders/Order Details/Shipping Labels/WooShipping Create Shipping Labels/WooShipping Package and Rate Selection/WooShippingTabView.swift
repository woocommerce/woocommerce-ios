import SwiftUI

struct WooShippingTabView: View {
    struct TabItem: Identifiable {
        let id = UUID()
        let icon: UIImage?
        let title: String
    }

    enum Layout {
        static let iconSize: CGFloat = 20.0
        static let horizontalContentPadding: CGFloat = 16.0
        static let verticalContentPadding: CGFloat = 9.0
        static let selectionIndicatorHeight: CGFloat = 3.0
    }

    let items: [TabItem]
    let titleFont: Font
    let selectedStateColor: Color
    let unselectedStateColor: Color
    @Binding var selectedItem: Int?

    private func itemContentView(_ item: TabItem, selected: Bool) -> some View {
        HStack {
            if let icon = item.icon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.iconSize, height: Layout.iconSize)
            }
            Text(item.title)
                .font(titleFont)
                .foregroundColor(selected ? selectedStateColor : unselectedStateColor)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        itemContentView(item, selected: selectedItem == index)
                            .padding(.horizontal, Layout.horizontalContentPadding)
                            .padding(.vertical, Layout.verticalContentPadding)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = index }
                        Rectangle()
                            .frame(height: Layout.selectionIndicatorHeight)
                            .foregroundColor(selectedItem == index ? selectedStateColor : Color.clear)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct WooShippingTabViewPreviewWrapper: View {
    @State private var selectedItem: Int? = 0
    private let items: [WooShippingTabView.TabItem] = [
        .init(icon: UIImage(named: "shipping-label-usps-logo"), title: "USPS"),
        .init(icon: UIImage(named: "shipping-label-dhl-logo"), title: "DHL Express"),
        .init(icon: UIImage(named: "shipping-label-usps-logo"), title: "USPS"),
        .init(icon: UIImage(named: "shipping-label-dhl-logo"), title: "DHL Express")
    ]

    var contentView: some View {
        WooShippingTabView(items: items,
                           titleFont: Font.subheadline.bold(),
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: Color.secondary,
                           selectedItem: $selectedItem)
        .accentColor(Color.purple)
    }

    var groupContent: some View {
        ScrollView {
            VStack {
                ForEach(ContentSizeCategory.allCases, id: \.self) { sizeCategory in
                    contentView
                        .environment(\.sizeCategory, sizeCategory)
                }
            }
        }
    }

    var body: some View {
        Group {
            groupContent
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            groupContent
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

struct WooShippingTabView_Previews: PreviewProvider {
    static var previews: some View {
        WooShippingTabViewPreviewWrapper()
    }
}
