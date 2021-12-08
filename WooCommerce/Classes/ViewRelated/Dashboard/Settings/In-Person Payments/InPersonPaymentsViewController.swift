import SwiftUI

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {
    init(viewModel: InPersonPaymentsViewModel) {
        super.init(rootView: InPersonPaymentsView(viewModel: viewModel))
        rootView.showSupport = {
            ZendeskProvider.shared.showNewWCPayRequestIfPossible(from: self)
        }
        rootView.showURL = { url in
            WebviewHelper.launch(url, with: self)
        }
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct InPersonPaymentsView: View {
    @StateObject var viewModel: InPersonPaymentsViewModel

    var showSupport: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                InPersonPaymentsLoading()
            case .countryNotSupported(let countryCode):
                InPersonPaymentsCountryNotSupported(countryCode: countryCode)
            case .wcpayNotInstalled:
                InPersonPaymentsPluginNotInstalled(onRefresh: viewModel.refresh)
            case .wcpayUnsupportedVersion:
                InPersonPaymentsPluginNotSupportedVersion(onRefresh: viewModel.refresh)
            case .wcpayNotActivated:
                InPersonPaymentsPluginNotActivated(onRefresh: viewModel.refresh)
            case .wcpayInTestModeWithLiveStripeAccount:
                InPersonPaymentsLiveSiteInTestMode(onRefresh:
                    viewModel.refresh)
            case .wcpaySetupNotCompleted:
                InPersonPaymentsWCPayNotSetup(onRefresh: viewModel.refresh)
            case .stripeAccountOverdueRequirement:
                InPersonPaymentsStripeAccountOverdue()
            case .stripeAccountPendingRequirement(let deadline):
                InPersonPaymentsStripeAccountPending(deadline: deadline)
            case .stripeAccountUnderReview:
                InPersonPaymentsStripeAcountReview()
            case .stripeAccountRejected:
                InPersonPaymentsStripeRejected()
            case .completed:
                InPersonPaymentsMenu()
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
            default:
                showURL?(url)
            }
        })
        .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments",
        comment: "Title for the In-Person Payments settings screen"
    )
}

struct InPersonPaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InPersonPaymentsView(viewModel: InPersonPaymentsViewModel(fixedState: .genericError))
        }
    }
}
