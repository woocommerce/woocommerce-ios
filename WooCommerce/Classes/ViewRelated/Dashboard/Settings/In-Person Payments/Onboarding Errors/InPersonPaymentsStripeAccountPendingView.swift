import SwiftUI

struct InPersonPaymentsStripeAccountPending: View {
    let viewModel: InPersonPaymentsStripeAccountPendingViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: Constants.imageHeight
            ),
            supportLink: true,
            learnMore: true,
            analyticReason: viewModel.analyticReason,
            plugin: viewModel.plugin,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: viewModel.skipButtonTitle,
                analyticReason: viewModel.analyticReason,
                plugin: viewModel.plugin,
                action: viewModel.onSkip
            )
        )
    }
}

struct InPersonPaymentsStripeAccountPending_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountPending(
            viewModel: InPersonPaymentsStripeAccountPendingViewModel(deadline: Date(), plugin: .wcPay, analyticReason: "", onSkip: {}))
    }
}

private enum Constants {
    static let imageHeight: CGFloat = 180.0
}
