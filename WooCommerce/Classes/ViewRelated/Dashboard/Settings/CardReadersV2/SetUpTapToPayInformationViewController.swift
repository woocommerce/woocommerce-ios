import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class SetUpTapToPayInformationViewController: UIHostingController<SetUpTapToPayInformationView>, PaymentSettingsFlowViewModelPresenter {

    private var viewModel: SetUpTapToPayInformationViewModel

    private lazy var alertsPresenter = CardPresentPaymentAlertsPresenter(rootViewController: self)

    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: BuiltInCardReaderConnectionController = {
        return BuiltInCardReaderConnectionController(
            forSiteID: viewModel.siteID,
            alertsPresenter: alertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: viewModel.configuration,
            analyticsTracker: viewModel.connectionAnalyticsTracker)
    }()

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? SetUpTapToPayInformationViewModel else {
            return nil
        }
        self.viewModel = viewModel

        super.init(rootView: SetUpTapToPayInformationView(viewModel: viewModel))

        viewModel.alertsPresenter = alertsPresenter
        viewModel.connectionController = connectionController
        configureView()
    }

    private func configureView() {
        rootView.showURL = { url in
            WebviewHelper.launch(url, with: self)
        }
        rootView.learnMoreUrl = viewModel.learnMoreURL
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

struct SetUpTapToPayInformationView: View {
    @ObservedObject var viewModel: SetUpTapToPayInformationViewModel
    var setUpButtonAction: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil
    var learnMoreUrl: URL? = nil
    var dismiss: (() -> Void)? = nil

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        verticalSizeClass == .compact
    }

    var imageMaxHeight: CGFloat {
        isCompact ? Constants.maxCompactImageHeight : Constants.maxImageHeight
    }

    var body: some View {
        VStack {
            HStack {
                Button("Cancel", action: {
                    dismiss?()
                })
                Spacer()
            }
            .padding(.top)

            Spacer()
            VStack {
                Text(Localization.setUpTapToPayOnIPhoneTitle)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing])
                    .fixedSize(horizontal: false, vertical: true)
                Image(uiImage: .setUpBuiltInReader)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: imageMaxHeight)
                    .padding()

                VStack(spacing: Constants.hintSpacing) {
                    PaymentSettingsFlowHint(title: Localization.hintOneTitle, text: Localization.hintOne)
                    PaymentSettingsFlowHint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
                    PaymentSettingsFlowHint(title: Localization.hintThreeTitle, text: Localization.hintThree)
                }
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .padding([.top, .bottom])

                Spacer()

                Button(Localization.setUpButton, action: {
                    viewModel.setUpTapped()
                })
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.setUpInProgress))
                .disabled(!viewModel.enableSetup)

                InPersonPaymentsLearnMore(
                    viewModel: LearnMoreViewModel(formatText: Localization.learnMore))
                .customOpenURL(action: { url in
                    switch url {
                    case LearnMoreViewModel.learnMoreURL:
                        if let url = learnMoreUrl {
                            showURL?(url)
                        }
                    default:
                        showURL?(url)
                    }
                })
            }
            .scrollVerticallyIfNeeded()
        }
        .padding()
    }
}

private enum Constants {
    // maxHeight should be 208, but that hides the button on iPhone SE
    // TODO: make this 208, or proportional to screen height for small screens
    // https://github.com/woocommerce/woocommerce-ios/issues/9134
    static let maxImageHeight: CGFloat = 180
    static let maxCompactImageHeight: CGFloat = 80
    static let hintSpacing: CGFloat = 16
}

private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Localization
//
private enum Localization {
    static let setUpTapToPayOnIPhoneTitle = NSLocalizedString(
        "Set up Tap to Pay on iPhone",
        comment: "Settings > Set up Tap to Pay on iPhone > Prompt user to set up Tap to Pay on iPhone"
    )

    static let hintOneTitle = NSLocalizedString(
        "1",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Help hint number 1"
    )

    static let hintOne = NSLocalizedString(
        "Make sure you are signed in to iCloud, and have set a passcode.",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Hint to sign in to " +
        "iCloud and set a passcode on the device"
    )

    static let hintTwoTitle = NSLocalizedString(
        "2",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Help hint number 2"
    )

    static let hintTwo = NSLocalizedString(
        "Accept the Terms of Service during set up.",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Hint to accept the " +
        "Terms of Service from Apple"
    )

    static let hintThreeTitle = NSLocalizedString(
        "3",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Help hint number 3"
    )

    static let hintThree = NSLocalizedString(
        "Try a payment using your own card (and refund it when you're done.)",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > Hint to try out payments " +
        "using their own card"
    )

    static let setUpButton = NSLocalizedString(
        "Set up Tap to Pay on iPhone",
        comment: "Settings > Set up Tap to Pay on iPhone > Information > A button to begin set up " +
        "for Tap to Pay on iPhone"
    )

    static let learnMore = NSLocalizedString(
        "%1$@ about accepting payments with Tap to Pay on iPhone.",
        comment: """
                 A label prompting users to learn more about Tap to Pay on iPhone"
                 %1$@ is a placeholder that always replaced with \"Learn more\" string,
                 which should be translated separately and considered part of this sentence.
                 """
    )
}

struct SetUpTapToPayInformationView_Previews: PreviewProvider {
    static var previews: some View {
        let config = CardPresentConfigurationLoader().configuration
        let viewModel = SetUpTapToPayInformationViewModel(
            siteID: 0,
            configuration: config,
            didChangeShouldShow: nil,
            activePaymentGateway: .wcPay,
            connectionAnalyticsTracker: .init(configuration: config))
        SetUpTapToPayInformationView(viewModel: viewModel,
                                     setUpButtonAction: {})
    }
}
