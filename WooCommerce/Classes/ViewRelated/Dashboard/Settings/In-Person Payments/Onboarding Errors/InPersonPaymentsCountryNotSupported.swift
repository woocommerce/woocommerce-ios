import SwiftUI

struct InPersonPaymentsCountryNotSupported: View {
    let viewModel: InPersonPaymentsCountryNotSupportedViewModel

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
            plugin: nil
        )
    }
}

struct InPersonPaymentsCountryNotSupported_Previews: PreviewProvider {
    static var previews: some View {
        // Valid country code
        InPersonPaymentsCountryNotSupported(viewModel: InPersonPaymentsCountryNotSupportedViewModel(countryCode: .ES, analyticReason: ""))
        // Invalid country code
        InPersonPaymentsCountryNotSupported(viewModel: InPersonPaymentsCountryNotSupportedViewModel(countryCode: .unknown, analyticReason: ""))
    }
}
