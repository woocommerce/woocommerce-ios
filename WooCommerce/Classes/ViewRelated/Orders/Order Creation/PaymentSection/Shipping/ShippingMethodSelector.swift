import SwiftUI

/// View to select a shipping method from a list of available shipping methods.
///
struct ShippingMethodSelector: View {
    /// Available shipping methods on the store.
    ///
    private let shippingMethods = ["Flat Rate", "Free Shipping", "Local Pickup", "Other"] // TODO-12612: Replace with actual shipping methods from the store

    /// The selected shipping method.
    ///
    @Binding var selectedMethod: String

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.verticalSpacing) {
                ForEach(shippingMethods, id: \.self) { method in
                    VStack(spacing: Layout.verticalSpacing) {
                        SelectableItemRow(title: method,
                                          selected: method == selectedMethod,
                                          displayMode: .compact,
                                          alignment: .trailing)
                        .onTapGesture {
                            selectedMethod = method
                        }
                        Divider().padding(.leading)
                    }
                }
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

// MARK: - Constants
private extension ShippingMethodSelector {
    enum Layout {
        static let verticalSpacing: CGFloat = 0
    }

    enum Localization {
        static let title = NSLocalizedString("order.ShippingMethodSelector.Title",
                                             value: "Method",
                                             comment: "Title for the screen to select a shipping method for an order")
    }
}

#Preview {
    ShippingMethodSelector(selectedMethod: .constant("Flat Rate"))
}
