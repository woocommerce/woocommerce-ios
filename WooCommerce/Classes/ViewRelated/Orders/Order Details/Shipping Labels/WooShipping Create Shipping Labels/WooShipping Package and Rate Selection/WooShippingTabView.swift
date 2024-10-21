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
    @Binding var selectedItem: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        HStack {
                            if let icon = item.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: Layout.iconSize, height: Layout.iconSize)
                            }
                            Text(item.title)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(selectedItem == index ? Color.accentColor : Color.secondary)
                        }
                        .padding(.horizontal, Layout.horizontalContentPadding)
                        .padding(.vertical, Layout.verticalContentPadding)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = index
                        }
                        Rectangle()
                            .frame(height: Layout.selectionIndicatorHeight)
                            .foregroundColor(selectedItem == index ? Color.accentColor : Color.clear)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct WooShippingTabViewPreviewWrapper: View {
    @State var selectedItem: Int? = 0
    let items: [WooShippingTabView.TabItem] = [
        WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-usps-logo"), title: "USPS"),
        WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-dhl-logo"), title: "DHL Express"),
        WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-usps-logo"), title: "USPS"),
        WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-dhl-logo"), title: "DHL Express")
    ]

    var contentView: some View {
        VStack {
            Spacer()
            WooShippingTabView(items: items, selectedItem: $selectedItem)
            Spacer()
        }
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
                .preferredColorScheme(.light)  // Light mode
                .previewDisplayName("Light Mode")
            groupContent
                .preferredColorScheme(.dark)  // Dark mode
                .previewDisplayName("Dark Mode")
        }
    }
}

struct WooShippingTabView_Previews: PreviewProvider {
    static var previews: some View {
        WooShippingTabViewPreviewWrapper()
    }
}
