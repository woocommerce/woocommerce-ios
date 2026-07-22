import SwiftUI

struct InPersonPaymentsLiveSiteInTestMode: View {
    let viewModel: InPersonPaymentsLiveSiteInTestModeViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: viewModel.plugin.image,
                height: 108.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: viewModel.analyticReason,
            plugin: viewModel.plugin,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: viewModel.refreshButtonTitle,
                analyticReason: viewModel.analyticReason,
                plugin: viewModel.plugin,
                action: viewModel.onRefresh
            )
        )
    }
}

struct InPersonPaymentsLiveSiteInTestMode_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLiveSiteInTestMode(viewModel: InPersonPaymentsLiveSiteInTestModeViewModel(plugin: .wcPay, analyticReason: "", onRefresh: {}))
    }
}
