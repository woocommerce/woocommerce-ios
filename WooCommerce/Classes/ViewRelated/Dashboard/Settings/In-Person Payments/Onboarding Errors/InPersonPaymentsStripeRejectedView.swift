import SwiftUI

struct InPersonPaymentsStripeRejected: View {
    let viewModel: InPersonPaymentsStripeRejectedViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true,
            analyticReason: viewModel.analyticReason,
            plugin: .stripe
        )
    }
}

struct InPersonPaymentsStripeRejected_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeRejected(viewModel: InPersonPaymentsStripeRejectedViewModel(analyticReason: ""))
    }
}
