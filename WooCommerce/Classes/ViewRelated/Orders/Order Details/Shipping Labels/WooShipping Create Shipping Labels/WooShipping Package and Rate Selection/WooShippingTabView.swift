import SwiftUI

struct WooShippingTabView: View {
    struct TabItem: Identifiable {
        let id = UUID()
        let icon: UIImage?
        let title: String
    }

    enum Layout {
        static let iconSize: CGFloat = 20.0
        static let selectionIndicatorHeight: CGFloat = 3.0
    }

    let items: [WooShippingTabView.TabItem]
    @Binding var selectedItem: Int?

    var body: some View {
        ScrollView(.horizontal) {
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
                        .padding()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = index
                        }
                        Rectangle()
                            .frame(height: Layout.selectionIndicatorHeight)
                            .foregroundColor(selectedItem == index ? Color.accentColor : Color.clear)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    struct Preview: View {
        @State var selectedItem: Int? = 0
        let items: [WooShippingTabView.TabItem] = [
            WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-usps-logo"), title: "USPS"),
            WooShippingTabView.TabItem(icon: UIImage(named: "shipping-label-dhl-logo"), title: "DHL Express")
        ]
        var body: some View {
            VStack {
                Spacer()
                WooShippingTabView(items: items, selectedItem: $selectedItem)
                Spacer()
            }
            .accentColor(.purple)
        }
    }

    return Preview()
}
