import SwiftUI

struct InPersonPaymentsPluginNotInstalled: View {
    let viewModel: InPersonPaymentsPluginNotInstalledViewModel

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: viewModel.title,
            message: viewModel.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .wcPayPlugin,
                height: 126.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: viewModel.analyticReason,
            plugin: nil,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: viewModel.installButtonTitle,
                analyticReason: viewModel.analyticReason,
                plugin: nil,
                action: viewModel.onInstall
            )
        )
    }
}

struct InPersonPaymentsPluginNotInstalled_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotInstalled(viewModel: InPersonPaymentsPluginNotInstalledViewModel(analyticReason: "", onInstall: {}))
    }
}
