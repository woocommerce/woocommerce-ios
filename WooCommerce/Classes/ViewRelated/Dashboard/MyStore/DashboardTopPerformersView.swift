import SwiftUI

/// Shows top performing products for a site in a given time range on the dashboard.
struct DashboardTopPerformersView: View {
    @ObservedObject private var viewModel: DashboardTopPerformersViewModel

    init(viewModel: DashboardTopPerformersViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.rows.isNotEmpty {
            TopPerformersView(itemTitle: Localization.productsTitle,
                              valueTitle: Localization.itemsSoldTitle,
                              rows: viewModel.rows,
                              isRedacted: viewModel.isRedacted)
            .padding(Layout.padding)
            .redacted(reason: viewModel.isRedacted ? .placeholder : [])
            .shimmering(active: viewModel.isRedacted)
        } else {
            TopPerformersEmptyView()
        }
    }
}

private extension DashboardTopPerformersView {
    enum Localization {
        static let productsTitle = NSLocalizedString(
            "Products",
            comment: "Title for the products card at the top of the top performers section in dashboard stats."
        )
        static let itemsSoldTitle = NSLocalizedString(
            "Items Sold",
            comment: "Title for the products card at the top of the top performers section in dashboard stats."
        )
    }

    enum Layout {
        static let padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}

struct DashboardTopPerformersView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardTopPerformersView(viewModel: .init(state: .loading, onTap: { _ in }))
        DashboardTopPerformersView(viewModel: .init(state: .loaded(rows: [.init(productID: 12,
                                                                                productName: "Fun product",
                                                                                quantity: 6,
                                                                                price: 12.8,
                                                                                total: 16.8,
                                                                                currency: "USD",
                                                                                imageUrl: nil)]), onTap: { _ in }))
    }
}
