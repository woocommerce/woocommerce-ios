import SwiftUI
import struct Yosemite.DashboardCard

/// View for displaying stock based on status on the dashboard.
///
struct ProductStockDashboardCard: View {
    @ObservedObject private var viewModel: ProductStockDashboardCardViewModel

    init(viewModel: ProductStockDashboardCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            filterBar
                .padding(.horizontal, Layout.padding)

            Divider()
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension ProductStockDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.stock.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissStock()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var filterBar: some View {
        HStack {
            Text(Localization.status)
                .foregroundStyle(Color.primaryText)
                .subheadlineStyle()
            Text(viewModel.selectedStockType.displayedName)
                .subheadlineStyle()
            Spacer()
            Menu {
                ForEach(ProductStockDashboardCardViewModel.StockType.allCases) { stockType in
                    Button {
                        viewModel.updateStockType(stockType)
                    } label: {
                        SelectableItemRow(title: stockType.displayedName, selected: stockType == viewModel.selectedStockType)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color(.secondaryLabel))
            }

        }
    }
}

private extension ProductStockDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let emptyStateImageWidth: CGFloat = 168
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "productStockDashboardCard.hideCard",
            value: "Hide Stock",
            comment: "Menu item to dismiss the Stock section on the My Store screen"
        )
        static let status = NSLocalizedString(
            "productStockDashboardCard.status",
            value: "Status",
            comment: "Header label on the Stock section on the My Store screen"
        )
    }
}

#Preview {
    ProductStockDashboardCard(viewModel: .init(siteID: 123))
}
