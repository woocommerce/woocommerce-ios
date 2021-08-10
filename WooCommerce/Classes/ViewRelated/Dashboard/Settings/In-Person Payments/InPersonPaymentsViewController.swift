import SwiftUI

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {
    init(viewModel: InPersonPaymentsViewModel) {
        super.init(rootView: InPersonPaymentsView(viewModel: viewModel))
        rootView.showSupport = {
            ZendeskManager.shared.showNewWCPayRequestIfPossible(from: self)
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
            if viewModel.showLoadingScreen {
                InPersonPaymentsLoading()
            } else {
                switch viewModel.state {
                case .countryNotSupported(let countryCode):
                    InPersonPaymentsCountryNotSupported(countryCode: countryCode)
                case .wcpayNotInstalled:
                    InPersonPaymentsPluginNotInstalled(onRefresh: viewModel.refresh)
                case .wcpayUnsupportedVersion:
                    InPersonPaymentsPluginNotSupportedVersionView(onRefresh: viewModel.refresh)
                case .wcpayNotActivated:
                    InPersonPaymentsPluginNotActivatedView(onRefresh: viewModel.refresh)
                case .stripeAccountOverdueRequirement:
                    InPersonPaymentsStripeAccountOverdue()
                case .completed:
                    CardReaderSettingsPresentingView()
                default:
                    InPersonPaymentsUnavailableView()
                }
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
