import SwiftUI

struct InPersonPaymentsPluginNotSupportedVersion: View {
    let viewModel: InPersonPaymentsPluginNotSupportedVersionViewModel

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

struct InPersonPaymentsPluginNotSupportedVersion_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotSupportedVersion(
            viewModel: InPersonPaymentsPluginNotSupportedVersionViewModel(plugin: .wcPay, analyticReason: "", onRefresh: {}))
    }
}
