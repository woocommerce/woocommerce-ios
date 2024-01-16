import SwiftUI

/// View to confirm the payment method before creating a Blaze campaign.
struct BlazeConfirmPaymentView: View {
    @ObservedObject private var viewModel: BlazeConfirmPaymentViewModel

    init(viewModel: BlazeConfirmPaymentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    BlazeConfirmPaymentView(viewModel: BlazeConfirmPaymentViewModel())
}
