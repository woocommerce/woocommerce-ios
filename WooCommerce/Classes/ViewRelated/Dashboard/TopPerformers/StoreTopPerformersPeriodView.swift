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
                Text(TopPerformersPeriodView.Localization.productsTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(TopPerformersPeriodView.Localization.itemsSoldTitle)
            }
            .storeTextStyle(.bodyMedium.emphasized)
            .foregroundStyle(.storeOnSurface)
            .padding(.horizontal, StorePadding.p5)
            .redacted(reason: viewModel.redacted.rows ? .placeholder : [])
            .shimmering(active: viewModel.redacted.rows)

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
