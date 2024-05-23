import SwiftUI

/// View for the order detail
///
struct OrderDetailView: View {

    /// Order to render
    ///
    let order: OrdersListView.Order

    var body: some View {
        TabView {
            // First
            summaryView

            // Second
            if order.itemCount > 0 {
                productsView
            }
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Text(order.number)
                    .font(.body)
                    .foregroundStyle(Colors.wooPurple20)
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Colors.wooPurpleBackground, .black]), startPoint: .top, endPoint: .bottom)
        )
    }

    /// First View: Summary
    ///
    @ViewBuilder private var summaryView: some View {
        VStack(alignment: .leading) {

            // Date & Time
            HStack {
                Text(order.date)
                Spacer()
                Text(order.time)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Divider()

            // Name, total, status
            VStack(alignment: .leading, spacing: Layout.nameSectionSpacing) {
                Text(order.name)
                    .font(.body)

                Text(order.total)
                    .font(.title2)
                    .bold()

                Text(order.status)
                    .font(.footnote)
                    .foregroundStyle(Colors.gray5)
            }
            .padding(.bottom, Layout.mainSectionsPadding)

            // Products button
            Button(Localization.products(order.itemCount).lowercased()) {
                print("product Button tapped")
            }
            .font(.caption2)
            .buttonStyle(.borderless)
            .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
            .padding()
            .background(Colors.whiteTransparent)
            .cornerRadius(Layout.buttonCornerRadius)
        }
    }

    /// Second View: Product List
    ///
    @ViewBuilder private var productsView: some View {
        List {
            Section {
                ForEach(order.items) { orderItem in
                    itemRow(orderItem)
                }
            } header: {
                Text(Localization.products(order.itemCount))
                    .font(.caption2)
                    .padding(.bottom)
            }
        }
    }

    /// Item Row of the product list
    ///
    @ViewBuilder private func itemRow(_ item: OrdersListView.OrderItem) -> some View {
        HStack(alignment: .top, spacing: Layout.itemRowSpacing) {

            // Item count
            Text(item.count.formatted(.number))
                .font(.caption2)
                .foregroundStyle(Colors.wooPurple20)
                .padding(Layout.itemCountPadding)
                .background(Circle().fill(Colors.whiteTransparent))

            // Name and total
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.caption2)

                Text(item.total)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical)
    }
}

private extension OrderDetailView {
    enum Layout {
        static let nameSectionSpacing = 2.0
        static let mainSectionsPadding = 10.0
        static let itemCountPadding = 6.0
        static let itemRowSpacing = 8.0
        static let buttonCornerRadius = 10.0
    }

    enum Localization {
        static func products(_ count: Int) -> LocalizedString {
            if count == 1 {
                return AppLocalizedString(
                    "watch.orders.detail.product-count-singular",
                    value: "%d Product",
                    comment: "Singular format for the number of products in the order detail screen."
                )
            }

            let format = AppLocalizedString(
                "watch.orders.detail.product-count",
                value: "%d Products",
                comment: "Plural format for the number of products in the order detail screen."
            )
            return LocalizedString(format: format, count)
        }
    }

    enum Colors {
        static let wooPurpleBackground = Color(red: 79/255.0, green: 54/255.0, blue: 125/255.0)
        static let gray5 = Color(red: 220/255.0, green: 220/255.0, blue: 222/255.0)
        static let wooPurple20 = Color(red: 190/255.0, green: 160/255.0, blue: 242/255.0)
        static let whiteTransparent = Color(white: 1.0, opacity: 0.12)
    }
}
