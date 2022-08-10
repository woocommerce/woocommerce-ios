import SwiftUI

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {
    private let onWillDisappear: (() -> ())?

    init(viewModel: InPersonPaymentsViewModel,
         onWillDisappear: (() -> ())? = nil) {
        self.onWillDisappear = onWillDisappear
        super.init(rootView: InPersonPaymentsView(viewModel: viewModel))
        rootView.showSupport = { [weak self] in
            guard let self = self else { return }
            ZendeskProvider.shared.showNewWCPayRequestIfPossible(from: self)
        }
        rootView.showURL = { [weak self] url in
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

    var showSupport: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil
    var shouldShowMenuOnCompletion: Bool = true

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                InPersonPaymentsLoading()
            case let .selectPlugin(pluginSelectionWasCleared):
                if viewModel.gatewaySelectionAvailable {
                    // Preselect WCPay only if there was no selection done before
                    InPersonPaymentsSelectPluginView(selectedPlugin: pluginSelectionWasCleared == true ? nil : .wcPay) { plugin in
                        viewModel.selectPlugin(plugin)
                        ServiceLocator.analytics.track(.cardPresentPaymentGatewaySelected, withProperties: ["payment_gateway": plugin.pluginName])
                    }
                } else if viewModel.userIsAdministrator {
                    InPersonPaymentsPluginConflictAdmin(onRefresh: viewModel.refresh)
                } else {
                    InPersonPaymentsPluginConflictShopManager(onRefresh: viewModel.refresh)
                }
            case let .pluginShouldBeDeactivated(plugin) where plugin == .stripe:
                InPersonPaymentsDeactivateStripeView(onRefresh: viewModel.refresh, showSetupPluginsButton: viewModel.userIsAdministrator)
            case .countryNotSupported(let countryCode):
                InPersonPaymentsCountryNotSupported(countryCode: countryCode)
            case .countryNotSupportedStripe(_, let countryCode):
                InPersonPaymentsCountryNotSupportedStripe(countryCode: countryCode)
            case .pluginNotInstalled:
                InPersonPaymentsPluginNotInstalled(onRefresh: viewModel.refresh)
            case .pluginUnsupportedVersion(let plugin):
                InPersonPaymentsPluginNotSupportedVersion(plugin: plugin, onRefresh: viewModel.refresh)
            case .pluginNotActivated(let plugin):
                InPersonPaymentsPluginNotActivated(plugin: plugin, onRefresh: viewModel.refresh)
            case .pluginInTestModeWithLiveStripeAccount(let plugin):
                InPersonPaymentsLiveSiteInTestMode(plugin: plugin, onRefresh:
                    viewModel.refresh)
            case .pluginSetupNotCompleted(let plugin):
                InPersonPaymentsPluginNotSetup(plugin: plugin, onRefresh: viewModel.refresh)
            case .stripeAccountOverdueRequirement:
                InPersonPaymentsStripeAccountOverdue()
            case .stripeAccountPendingRequirement(_, let deadline):
                InPersonPaymentsStripeAccountPending(deadline: deadline)
            case .stripeAccountUnderReview:
                InPersonPaymentsStripeAccountReview()
            case .stripeAccountRejected:
                InPersonPaymentsStripeRejected()
            case .completed(let pluginState):
                if viewModel.showMenuOnCompletion {
                    InPersonPaymentsMenu(
                        pluginState: pluginState,
                        onPluginSelected: { plugin in
                            viewModel.selectPlugin(plugin)
                        },
                        onPluginSelectionCleared: {
                            viewModel.clearPluginSelection()
                        })
                } else {
                    InPersonPaymentsCompleted()
                }
            case .noConnectionError:
                InPersonPaymentsNoConnection(onRefresh: viewModel.refresh)
            default:
                InPersonPaymentsUnavailable()
            }
        }
        .customOpenURL(action: { url in
            switch url {
            case InPersonPaymentsSupportLink.supportURL:
                showSupport?()
            case InPersonPaymentsLearnMore.learnMoreURL:
                if let url = viewModel.learnMoreURL {
                    showURL?(url)
                }
            default:
                showURL?(url)
            }
        })
        .navigationTitle(Localization.title)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "In-Person Payments",
            comment: "Title for the In-Person Payments settings screen"
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
