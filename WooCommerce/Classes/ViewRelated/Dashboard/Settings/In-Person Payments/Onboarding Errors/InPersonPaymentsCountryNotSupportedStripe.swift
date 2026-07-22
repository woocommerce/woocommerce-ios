import SwiftUI

struct InPersonPaymentsCountryNotSupportedStripe: View {
    let viewModel: InPersonPaymentsCountryNotSupportedStripeViewModel

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

struct InPersonPaymentsCountryNotSupportedStripe_Previews: PreviewProvider {
    static var previews: some View {
        // Valid country code
        InPersonPaymentsCountryNotSupportedStripe(viewModel: InPersonPaymentsCountryNotSupportedStripeViewModel(countryCode: .ES, analyticReason: ""))
        // Invalid country code
        InPersonPaymentsCountryNotSupportedStripe(viewModel: InPersonPaymentsCountryNotSupportedStripeViewModel(countryCode: .unknown, analyticReason: ""))
    }
}
