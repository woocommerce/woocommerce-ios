import SwiftUI

struct POSCheckoutView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Text("Checkout placeholder")
                .navigationTitle(Localization.checkout)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(Localization.back) {
                            isPresented = false
                        }
                    }
                }
        }
    }

    private enum Localization {
        static let checkout = NSLocalizedString(
            "pos.phone.checkout.title",
            value: "Checkout",
            comment: "Title for the checkout screen in phone POS"
        )
        static let back = NSLocalizedString(
            "pos.phone.checkout.back",
            value: "Back",
            comment: "Back button title on the phone POS checkout screen"
        )
    }
}
