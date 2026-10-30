import StoreDesignSystem
import SwiftUI

struct StoreTopPerformersPeriodView: View {
    @ObservedObject private var viewModel: TopPerformersPeriodViewModel

    init(viewModel: TopPerformersPeriodViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            HStack(spacing: StoreSpacing.s3) {
                Text(Localization.productsTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Localization.itemsSoldTitle)
            }
            .storeTextStyle(.bodyMedium.emphasized)
            .foregroundStyle(.storeOnSurface)
            .padding(.horizontal, StorePadding.p5)

            if viewModel.rows.isNotEmpty {
                VStack(spacing: StoreSpacing.s0) {
                    ForEach(viewModel.rows.indexed(), id: \.0) { index, row in
                        StoreTopPerformersRow(data: row, showsDivider: index < viewModel.rows.count - 1)
                    }
                }
                .padding(.top, StorePadding.p3)
                .redacted(reason: viewModel.redacted.rows ? .placeholder : [])
                .shimmering(active: viewModel.redacted.rows)
            } else {
                StoreTopPerformersEmptyView()
            }
        }
    }
}

private extension StoreTopPerformersPeriodView {
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
}
