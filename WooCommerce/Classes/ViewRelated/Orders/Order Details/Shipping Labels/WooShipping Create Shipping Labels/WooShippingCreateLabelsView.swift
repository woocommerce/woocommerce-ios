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
                // TODO-13550: Add main UI for new shipping labels flow.
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
