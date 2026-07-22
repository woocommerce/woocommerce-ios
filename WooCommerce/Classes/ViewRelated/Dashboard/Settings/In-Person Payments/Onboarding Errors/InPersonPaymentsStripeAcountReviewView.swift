import SwiftUI

struct InPersonPaymentsStripeAccountReview: View {
    let viewModel: InPersonPaymentsStripeAccountReviewViewModel

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

struct InPersonPaymentsStripeAccountReview_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountReview(viewModel: InPersonPaymentsStripeAccountReviewViewModel(analyticReason: ""))
    }
}
