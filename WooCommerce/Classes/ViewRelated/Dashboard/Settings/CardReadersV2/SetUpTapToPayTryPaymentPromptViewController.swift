import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class SetUpTapToPayTryPaymentPromptViewController: UIHostingController<SetUpTapToPayPaymentPromptView>, PaymentSettingsFlowViewModelPresenter {

    private var viewModel: SetUpTapToPayTryPaymentPromptViewModel

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? SetUpTapToPayTryPaymentPromptViewModel else {
            return nil
        }
        self.viewModel = viewModel

        super.init(rootView: SetUpTapToPayPaymentPromptView(viewModel: viewModel))

        configureViewModel()
        configureView()
    }

    private func configureViewModel() {
        viewModel.dismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func configureView() {
        rootView.rootViewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

struct SetUpTapToPayPaymentPromptView: View {
    @ObservedObject var viewModel: SetUpTapToPayTryPaymentPromptViewModel
    weak var rootViewController: UIViewController?

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        verticalSizeClass == .compact
    }

    var imageMaxHeight: CGFloat {
        isCompact ? Constants.maxCompactImageHeight : Constants.maxImageHeight
    }

    var imageFontSize: CGFloat {
        isCompact ? Constants.maxCompactImageHeight : Constants.imageFontSize
    }

    var body: some View {
        ScrollableVStack(padding: 0) {
            Image(systemName: "wave.3.right.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(.wooCommercePurple(.shade50)))
                .scaledToFit()
                .frame(maxHeight: imageMaxHeight)
                .font(.system(size: imageFontSize))
                .padding()

            Text(Localization.setUpTryPaymentPromptTitle)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            Text(Localization.setUpTryPaymentPromptDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(Localization.tryAPaymentButton, action: {
                viewModel.tryAPaymentTapped()
            })
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.loading))

            Button(Localization.skipButton, action: {
                viewModel.skipTapped()
            })
            .buttonStyle(SecondaryButtonStyle())

            LazyNavigationLink(destination: paymentFlow(), isActive: $viewModel.summaryActive) {
                EmptyView()
            }
        }
        .padding()
    }

    /// Returns a `SimplePaymentsSummary` instance when the view model is available.
    ///
    private func paymentFlow() -> some View {
        WooNavigationSheet(viewModel: WooNavigationSheetViewModel(navigationTitle: Localization.setUpTryPaymentPromptTitle,
                                                                  done: viewModel.dismiss ?? {})) {
            if let summaryViewModel = viewModel.summaryViewModel {
                SimplePaymentsSummary(
                    dismiss: {
                        showOrder(orderID: summaryViewModel.orderID, siteID: summaryViewModel.siteID)
                    },
                    rootViewController: rootViewController?.navigationController,
                    viewModel: summaryViewModel.simplePaymentSummaryViewModel)
            }
            EmptyView()
        }
    }

    private func showOrder(orderID: Int64, siteID: Int64) {
        let orderViewController = OrderLoaderViewController(orderID: orderID, siteID: siteID)
        orderViewController.addCloseNavigationBarButton(title: Localization.doneButton)
        rootViewController?.navigationController?.navigationBar.isHidden = false
        rootViewController?.navigationController?.setViewControllers([orderViewController], animated: true)
    }
}

private enum Constants {
    static let maxImageHeight: CGFloat = 180
    static let maxCompactImageHeight: CGFloat = 80
    static let imageFontSize: CGFloat = 120
    static let compactImageFontSize: CGFloat = 40
}

// MARK: - Localization
//
private extension SetUpTapToPayPaymentPromptView {
    enum Localization {
        static let setUpTryPaymentPromptTitle = NSLocalizedString(
            "Try a payment",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Inform user that " +
            "Tap to Pay on iPhone is ready"
        )

        static let setUpTryPaymentPromptDescription = NSLocalizedString(
            "Try taking a payment of $0.50 to see how Tap to Pay on iPhone works. Use your " +
            "debit or credit card: you can refund it when you're done.",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Description"
        )

        static let tryAPaymentButton = NSLocalizedString(
            "Try a Payment",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > A button to start " +
            "a payment for testing Tap to Pay on iPhone using the merchant's own card."
        )

        static let skipButton = NSLocalizedString(
            "Skip",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > A button to skip " +
            "to the trial payment and dismiss the Set up Tap to Pay on iPhone flow"
        )

        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Payment flow " +
            "> Cancel button")

        static let doneButton = NSLocalizedString(
            "Done",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Payment flow " +
            "> Review Order > Done button")
    }
}

struct SetUpTapToPayPaymentPromptView_Previews: PreviewProvider {
    static var previews: some View {

        let config = CardPresentConfigurationLoader().configuration
        let viewModel = SetUpTapToPayTryPaymentPromptViewModel(
            didChangeShouldShow: nil,
            connectionAnalyticsTracker: .init(configuration: config))
        SetUpTapToPayPaymentPromptView(viewModel: viewModel)
    }
}
