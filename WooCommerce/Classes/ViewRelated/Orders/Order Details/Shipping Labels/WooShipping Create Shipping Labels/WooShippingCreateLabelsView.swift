import SwiftUI

/// Hosting controller for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewHostingController: UIHostingController<WooShippingCreateLabelsView> {
    init() {
        super.init(rootView: WooShippingCreateLabelsView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to create shipping labels with the Woo Shipping extension.
///
struct WooShippingCreateLabelsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                // TODO-13550: Add view model to provide real data
                WooShippingItems(itemsCountLabel: "6 items",
                                 itemsDetailLabel: "825g  ·  $135.00",
                                 items: [WooShippingItemRowViewModel(imageUrl: nil,
                                                                     quantityLabel: "3",
                                                                     name: "Little Nap Brazil 250g",
                                                                     detailsLabel: "15×10×8cm • Espresso",
                                                                     weightLabel: "275g",
                                                                     priceLabel: "$60.00"),
                                         WooShippingItemRowViewModel(imageUrl: nil,
                                                                     quantityLabel: "30",
                                                                     name: "Little Nap Brazil 250g",
                                                                     detailsLabel: "15×10×8cm • Espresso",
                                                                     weightLabel: "275g",
                                                                     priceLabel: "$60.00")])
                    .padding()
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension WooShippingCreateLabelsView {
    enum Localization {
        static let title = NSLocalizedString("wooShipping.createLabels.title",
                                             value: "Create Shipping Labels",
                                             comment: "Title for the screen to create a shipping label")
        static let cancel = NSLocalizedString("wooShipping.createLabel.cancelButton",
                                              value: "Cancel",
                                              comment: "Title of the button to dismiss the shipping label creation screen")
    }
}

#Preview {
    WooShippingCreateLabelsView()
}
