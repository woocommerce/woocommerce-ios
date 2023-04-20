import SwiftUI
import Yosemite

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {

    private let onWillDisappear: (() -> ())?

    init(viewModel: InPersonPaymentsViewModel,
         onWillDisappear: (() -> ())?) {
        self.onWillDisappear = onWillDisappear
        super.init(rootView: InPersonPaymentsView(viewModel: viewModel))
        viewModel.showSupport = { [weak self] in
            guard let self = self else { return }
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        }
        viewModel.showURL = { [weak self] url in
            guard let self = self else { return }
            WebviewHelper.launch(url, with: self)
        }
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        onWillDisappear?()
        super.viewWillDisappear(animated)
    }
}

struct InPersonPaymentsView: View {
    @StateObject var viewModel: InPersonPaymentsViewModel
    var shouldShowMenuOnCompletion: Bool = true

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                InPersonPaymentsLoading()
            case let .selectPlugin(pluginSelectionWasCleared):
                // Preselect WCPay only if there was no selection done before
                InPersonPaymentsSelectPluginView(selectedPlugin: pluginSelectionWasCleared == true ? nil : .wcPay) { plugin in
                    viewModel.selectPlugin(plugin)
                    ServiceLocator.analytics.track(.cardPresentPaymentGatewaySelected, withProperties: ["payment_gateway": plugin.pluginName])
                }
            case .countryNotSupported(let countryCode):
                InPersonPaymentsCountryNotSupported(countryCode: countryCode, analyticReason: viewModel.state.reasonForAnalytics)
            case .countryNotSupportedStripe(_, let countryCode):
                InPersonPaymentsCountryNotSupportedStripe(countryCode: countryCode, analyticReason: viewModel.state.reasonForAnalytics)
            case .pluginNotInstalled:
                InPersonPaymentsPluginNotInstalled(analyticReason: viewModel.state.reasonForAnalytics, onRefresh: viewModel.refresh)
            case .pluginUnsupportedVersion(let plugin):
                InPersonPaymentsPluginNotSupportedVersion(plugin: plugin, analyticReason: viewModel.state.reasonForAnalytics, onRefresh: viewModel.refresh)
            case .pluginNotActivated(let plugin):
                InPersonPaymentsPluginNotActivated(plugin: plugin, analyticReason: viewModel.state.reasonForAnalytics, onRefresh: viewModel.refresh)
            case .pluginInTestModeWithLiveStripeAccount(let plugin):
                InPersonPaymentsLiveSiteInTestMode(plugin: plugin, analyticReason: viewModel.state.reasonForAnalytics, onRefresh:
                    viewModel.refresh)
            case .pluginSetupNotCompleted(let plugin):
                InPersonPaymentsPluginNotSetup(plugin: plugin, analyticReason: viewModel.state.reasonForAnalytics, onRefresh: viewModel.refresh)
            case .stripeAccountOverdueRequirement:
                InPersonPaymentsStripeAccountOverdue(analyticReason: viewModel.state.reasonForAnalytics)
            case .stripeAccountPendingRequirement(_, let deadline):
                InPersonPaymentsStripeAccountPending(
                    deadline: deadline,
                    analyticReason: viewModel.state.reasonForAnalytics,
                    onSkip: viewModel.skipPendingRequirements)
            case .stripeAccountUnderReview:
                InPersonPaymentsStripeAccountReview(analyticReason: viewModel.state.reasonForAnalytics)
            case .stripeAccountRejected:
                InPersonPaymentsStripeRejected(analyticReason: viewModel.state.reasonForAnalytics)
            case .codPaymentGatewayNotSetUp(let plugin):
                InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpView(
                    viewModel: InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
                        plugin: plugin,
                        analyticReason: viewModel.state.reasonForAnalytics,
                        completion: viewModel.refresh))
            case .completed:
                InPersonPaymentsCompleted()
            case .noConnectionError:
                InPersonPaymentsNoConnection(analyticReason: viewModel.state.reasonForAnalytics, onRefresh: viewModel.refresh)
            default:
                InPersonPaymentsUnavailable(analyticReason: viewModel.state.reasonForAnalytics)
            }
        }
        .customOpenURL(action: { url in
            switch url {
            case InPersonPaymentsSupportLink.supportURL:
                viewModel.showSupport?()
            case LearnMoreViewModel.learnMoreURL:
                if let url = viewModel.learnMoreURL {
                    viewModel.showURL?(url)
                }
            default:
                viewModel.showURL?(url)
            }
        })
        .navigationTitle(Localization.title)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Payments",
            comment: "Title for the Payments settings screen"
        )
    }
}

struct InPersonPaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InPersonPaymentsView(viewModel: InPersonPaymentsViewModel(fixedState: .completed(plugin: .stripeOnly)))
        }
    }
}
