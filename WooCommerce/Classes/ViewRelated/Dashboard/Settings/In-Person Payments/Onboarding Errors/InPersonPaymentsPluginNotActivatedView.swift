import SwiftUI

struct InPersonPaymentsPluginNotActivated: View {
    let viewModel: InPersonPaymentsPluginNotActivatedViewModel

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
                text: viewModel.activateButtonTitle,
                analyticReason: viewModel.analyticReason,
                plugin: viewModel.plugin,
                action: viewModel.onActivate
            )
        )
    }
}

struct InPersonPaymentsPluginNotActivated_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotActivated(viewModel: InPersonPaymentsPluginNotActivatedViewModel(plugin: .wcPay, analyticReason: "", onActivate: {}))
    }
}
