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
    var body: some View {
        // TODO-13550: Replace placeholder content with real UI for new shipping labels flow.
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    WooShippingCreateLabelsView()
}
