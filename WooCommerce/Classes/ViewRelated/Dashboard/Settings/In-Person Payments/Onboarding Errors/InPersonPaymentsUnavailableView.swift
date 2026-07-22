import SwiftUI

struct InPersonPaymentsUnavailable: View {
    let viewModel: InPersonPaymentsUnavailableViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: viewModel.analyticReason,
            plugin: nil
        )
    }
}

struct InPersonPaymentsUnavailable_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailable(viewModel: InPersonPaymentsUnavailableViewModel(analyticReason: ""))
    }
}
