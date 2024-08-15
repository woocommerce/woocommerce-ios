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

    override func viewDidAppear(_ animated: Bool) {
        viewModel.onAppear()
        super.viewDidAppear(animated)
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

            Text(String(format: Localization.setUpTryPaymentPromptDescription, viewModel.formattedPaymentAmount))
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
        }
        .navigationDestination(isPresented: $viewModel.summaryActive) {
            if let summaryViewModel = viewModel.summaryViewModel {
                paymentFlow(summaryViewModel: summaryViewModel)
            }
        }
        .navigationDestination(isPresented: $viewModel.refundInProgress) {
            ProgressView()
        }
        .navigationDestination(isPresented: $viewModel.shouldShowTrialOrderDetails) {
            if let summaryViewModel = viewModel.summaryViewModel {
                completedOrder(summaryViewModel: summaryViewModel)
            }
        }
        .padding()
    }

    /// Returns a `SimplePaymentsSummary` instance when the view model is available.
    ///
    private func paymentFlow(summaryViewModel: TryAPaymentSummaryViewModel) -> some View {
        SimplePaymentsSummary(
            dismiss: viewModel.onTrialPaymentFlowFinished,
            rootViewController: rootViewController?.navigationController,
            viewModel: summaryViewModel.simplePaymentSummaryViewModel)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    viewModel.onDismiss()
                },
                       label: {
                    Text(Localization.doneButton)
                })
            }
        }
        .navigationBarHidden(false)
    }

    private func completedOrder(summaryViewModel: TryAPaymentSummaryViewModel) -> some View {
        OrderLoaderView(orderID: summaryViewModel.orderID, siteID: summaryViewModel.siteID)
            .navigationTitle(Localization.paymentCompleteNavigationTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.dismiss?()
                    },
                           label: {
                        Text(Localization.doneButton)
                    })
                }
            }
            .navigationBarBackButtonHidden()
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
            "Would you like to try a payment",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Inform user that " +
            "Tap to Pay on iPhone is ready"
        )

        static let setUpTryPaymentPromptDescription = NSLocalizedString(
            "Try a %1$@ payment with your debit or credit card. You can refund the payment when you’re done.",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > Description. %1$@ will be replaced " +
            "with the amount of the trial payment, in the store's currency."
        )

        static let tryAPaymentButton = NSLocalizedString(
            "Try a Payment",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > A button to start " +
            "a payment for testing Tap to Pay on iPhone using the merchant's own card."
        )

        static let skipButton = NSLocalizedString(
            "Return to Payments",
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

        static let paymentCompleteNavigationTitle = NSLocalizedString(
            "setUpTapToPayPaymentPromptView.paymentComplete.navigation.title",
            value: "Payment Complete",
            comment: "Settings > Set up Tap to Pay on iPhone > Try a Payment > After trying a payments, the merchant " +
            "is shown an order confirmation screen, showing their payment was successful and allowing them to refund " +
            "themselves. This is the navigation bar title for that screen.")
    }
}

struct SetUpTapToPayPaymentPromptView_Previews: PreviewProvider {
    static var previews: some View {

        let config = CardPresentConfigurationLoader().configuration
        let viewModel = SetUpTapToPayTryPaymentPromptViewModel(
            didChangeShouldShow: nil,
            connectionAnalyticsTracker: .init(configuration: config,
                                              siteID: 0, connectionType: .userInitiated))
        SetUpTapToPayPaymentPromptView(viewModel: viewModel)
    }
}
