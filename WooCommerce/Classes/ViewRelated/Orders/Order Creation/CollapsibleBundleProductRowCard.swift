import Yosemite
import SwiftUI

/// Displays a collapsible product row for a bundle product parent item, grouped with its child items
///
struct CollapsibleBundleProductRowCard: View {
    /// View model for the parent product
    @ObservedObject var parentViewModel: ProductRowViewModel

    /// View models for the child products
    var childViewModels: [ProductRowViewModel]

    /// Used for tracking order form events.
    let flow: WooAnalyticsEvent.Orders.Flow

    var onAddDiscount: () -> Void

    /// Tracks if discount editing should be enabled or disabled. False by default
    var shouldDisableDiscountEditing: Bool = false

    /// Tracks if discount should be allowed or disallowed.
    var shouldDisallowDiscounts: Bool = false

    @ScaledMetric private var scale: CGFloat = 1

    init(parentViewModel: ProductRowViewModel,
         childViewModels: [ProductRowViewModel],
         flow: WooAnalyticsEvent.Orders.Flow,
         shouldDisableDiscountEditing: Bool,
         shouldDisallowDiscounts: Bool,
         onAddDiscount: @escaping () -> Void) {
        self.parentViewModel = parentViewModel
        self.childViewModels = childViewModels
        self.flow = flow
        self.shouldDisableDiscountEditing = shouldDisableDiscountEditing
        self.shouldDisallowDiscounts = shouldDisallowDiscounts
        self.onAddDiscount = onAddDiscount
    }

    var body: some View {
        VStack(spacing: 0) {
            // Parent product
            CollapsibleProductRowCard(viewModel: parentViewModel,
                                      flow: flow,
                                      shouldDisableDiscountEditing: shouldDisableDiscountEditing,
                                      shouldDisallowDiscounts: shouldDisallowDiscounts,
                                      onAddDiscount: onAddDiscount)
            Divider()
                .frame(height: Layout.borderLineWidth)
                .overlay(Color(.separator))

            // Child products
            ForEach(childViewModels) { viewModel in
                CollapsibleProductRowCard(viewModel: viewModel,
                                          flow: flow,
                                          shouldDisableDiscountEditing: shouldDisableDiscountEditing,
                                          shouldDisallowDiscounts: shouldDisallowDiscounts,
                                          onAddDiscount: onAddDiscount) // TODO: #11250 Update design of child items in product bundle
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
        }
    }
}

private extension CollapsibleBundleProductRowCard {
    enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
    }
}

#if DEBUG
#Preview {
    let product = Product.swiftUIPreviewSample()
    let parentViewModel = ProductRowViewModel(id: 1, product: product, canChangeQuantity: true, hasChildProducts: true)
    let childViewModels = [ProductRowViewModel(id: 2, product: product, canChangeQuantity: true, hasParentProduct: true),
                           ProductRowViewModel(id: 3, product: product, canChangeQuantity: true, hasParentProduct: true)]
    return CollapsibleBundleProductRowCard(parentViewModel: parentViewModel,
                                           childViewModels: childViewModels,
                                           flow: .creation,
                                           shouldDisableDiscountEditing: false,
                                           shouldDisallowDiscounts: false,
                                           onAddDiscount: {})
    .padding()
}
#endif
