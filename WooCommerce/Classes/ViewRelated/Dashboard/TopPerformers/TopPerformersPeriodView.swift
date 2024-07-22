import SwiftUI

/// Shows top performing products for a site in a given time range on the dashboard.
struct TopPerformersPeriodView: View {
    @ObservedObject private var viewModel: TopPerformersPeriodViewModel

    init(viewModel: TopPerformersPeriodViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.rows.isNotEmpty {
            TopPerformersView(itemTitle: Localization.productsTitle,
                              valueTitle: Localization.itemsSoldTitle,
                              rows: viewModel.rows,
                              isRedacted: viewModel.redacted.rows)
            .padding(Layout.padding)
            .redacted(reason: viewModel.redacted.rows ? .placeholder : [])
            .shimmering(active: viewModel.redacted.rows)
        } else {
            TopPerformersEmptyView()
        }
    }
}

private extension TopPerformersPeriodView {
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
        static let padding = EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
    }
}

struct DashboardTopPerformersView_Previews: PreviewProvider {
    static var previews: some View {
        TopPerformersPeriodView(viewModel: .init(state: .loading(cached: []), onTap: { _ in }))
        TopPerformersPeriodView(viewModel: .init(state: .loaded(rows: [.init(productID: 12,
                                                                                productName: "Fun product",
                                                                                quantity: 6,
                                                                                total: 16.8,
                                                                                currency: "USD",
                                                                                imageUrl: nil)]), onTap: { _ in }))
    }
}
