import SwiftUI

struct InPersonPaymentsNoConnection: View {
    let viewModel: InPersonPaymentsNoConnectionViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .errorStateImage,
                height: 108.0
            ),
            supportLink: false,
            learnMore: false,
            analyticReason: viewModel.analyticReason,
            plugin: nil,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: viewModel.retryButtonTitle,
                analyticReason: viewModel.analyticReason,
                plugin: nil,
                action: viewModel.onRefresh
            )
        )
    }
}

struct InPersonPaymentsNoConnection_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsNoConnection(viewModel: InPersonPaymentsNoConnectionViewModel(analyticReason: "", onRefresh: {}))
    }
}
