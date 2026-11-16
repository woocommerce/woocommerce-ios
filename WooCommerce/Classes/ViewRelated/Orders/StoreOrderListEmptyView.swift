import StoreDesignSystem
import SwiftUI

struct StoreOrderListEmptyView: View {
    let filterDescription: String?
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: StoreSpacing.s8) {
            Image(uiImage: image)
                .accessibilityHidden(true)

            VStack(spacing: StoreSpacing.s5) {
                Text(title)
                    .storeTextStyle(.titleLarge.strong)
                    .foregroundStyle(.storeOnSectionBackground)
                    .multilineTextAlignment(.center)

                if filterDescription == nil {
                    Text(OrderListLocalization.allOrdersEmptyStateDetail)
                        .storeTextStyle(.bodyLarge)
                        .foregroundStyle(.storeOnSectionBackgroundVariant)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: Constants.maximumTextWidth)

            StoreButton(actionTitle,
                        variant: filterDescription == nil ? .filled : .outlined,
                        size: .medium,
                        action: onAction)
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.vertical, StorePadding.p8)
        .containerRelativeFrame(.vertical)
        .frame(maxWidth: .infinity)
        .background(.storeSectionBackground)
    }

    private var image: UIImage {
        filterDescription == nil ? .boxesImage : .magnifyingGlassNotFound
    }

    private var title: String {
        guard let filterDescription else {
            return OrderListLocalization.allOrdersEmptyStateMessage
        }
        return String.localizedStringWithFormat(OrderListLocalization.filteredOrdersEmptyStateMessage, filterDescription)
    }

    private var actionTitle: String {
        filterDescription == nil ? OrderListLocalization.learnMore : OrderListLocalization.clearFilters
    }
}

private extension StoreOrderListEmptyView {
    enum Constants {
        static let maximumTextWidth = StorePadding.p12 * 4
    }
}
