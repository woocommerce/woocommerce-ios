import SwiftUI

/// View for the order detail
///
struct OrderDetailView: View {

    @EnvironmentObject private var tracksProvider: WatchTracksProvider

    /// Order to render
    ///
    let order: OrdersListView.Order

    /// Tracks the selected tab.
    ///
    @State private var selectedTab = Tab.summary

    var body: some View {
        TabView(selection: $selectedTab) {
            // First
            summaryView
                .tag(Tab.summary)
                .padding(.horizontal)

            // Second
            if order.itemCount > 0 {
                productsView
                    .tag(Tab.products)
            }

            // Third
            customerView
                .tag(Tab.customer)
        }
        .navigationTitle {
            Text(order.number)
                .font(.body)
                .foregroundStyle(Color.withColorStudio(name: .wooCommercePurple, shade: .shade20))
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.withColorStudio(name: .wooCommercePurple, shade: .shade70),
                                                       .black]),
                           startPoint: .top,
                           endPoint: .bottom)
        )
        .compatibleVerticalStyle()
        .onAppear() {
            tracksProvider.sendTracksEvent(.watchOrderDetailOpened)
        }
    }

    /// First View: Summary
    ///
    @ViewBuilder private var summaryView: some View {
        ScrollView {
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
                        .fixedSize(horizontal: false, vertical: true)

                    Text(order.total)
                        .font(.title2)
                        .bold()

                    Text(order.status)
                        .font(.footnote)
                        .foregroundStyle(Color.withColorStudio(name: .gray, shade: .shade5))
                }
                .padding(.bottom, Layout.mainSectionsPadding)

                // Products button
                Button(Localization.products(order.itemCount).lowercased()) {
                    if order.itemCount > 0 {
                        self.selectedTab = .products
                    }
                }
                .font(.caption2)
                .buttonStyle(.borderless)
                .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                .padding()
                .background(Colors.whiteTransparent)
                .cornerRadius(Layout.buttonCornerRadius)
            }
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
            }
            .listStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: Layout.itemlistPadding, bottom: 0, trailing: Layout.itemlistPadding))
        }
    }

    /// Item Row of the product list
    ///
    @ViewBuilder private func itemRow(_ item: OrdersListView.OrderItem) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top, spacing: Layout.itemRowSpacing) {

                // Item count
                Text(item.count.formatted(.number))
                    .font(.caption2)
                    .foregroundStyle(Color.withColorStudio(name: .wooCommercePurple, shade: .shade20))
                    .padding(Layout.itemCountPadding)
                    .background(Circle().fill(Colors.whiteTransparent))
                    .padding(.top, -5) // Offset the number a bit so it looks aligned to the other content

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

            if item.showDivider {
                Divider()
            }
        }
    }

    /// Third View Customer & Address section
    ///
    @ViewBuilder private var customerView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Layout.nameSectionSpacing) {
                    // name
                    Text(order.name)
                        .font(.body)

                    // Email if exists
                    if order.email.isNotEmpty {
                        Text(order.email)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .padding(.top, Layout.customerDividerPadding)
                }

                // Address
                Text(order.address)
                    .font(.caption2)
            } header: {
                Text(Localization.customer)
                    .font(.caption2)
                    .padding(.bottom)
            }
            .listStyle(.plain)
            .listRowBackground(Color.clear)
        }
    }
}

private extension OrderDetailView {
    enum Tab: Int {
        case summary
        case products
        case customer
    }

    enum Layout {
        static let nameSectionSpacing = 2.0
        static let customerDividerPadding = 6.0
        static let mainSectionsPadding = 10.0
        static let itemCountPadding = 6.0
        static let itemRowSpacing = 8.0
        static let buttonCornerRadius = 10.0
        static let itemlistPadding = 5.0
    }

    enum Localization {
        static func products(_ count: Int) -> LocalizedString {
            if count == 1 {
                return AppLocalizedString(
                    "watch.orders.detail.product-count-singular",
                    value: "1 Product",
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

        static let customer = AppLocalizedString(
            "watch.orders.detail.customer",
            value: "Customer",
            comment: "Customer title in the order detail screen."
        )
    }

    enum Colors {
        static let whiteTransparent = Color(white: 1.0, opacity: 0.12)
    }
}
