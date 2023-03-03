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

        super.init(rootView: SetUpTapToPayInformationView())
        configureView()
    }

    private func configureView() {
        rootView.setUpButtonAction = { [weak self] in
            self?.searchAndConnect()
        }
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

// MARK: - Convenience Methods
//
private extension SetUpTapToPayInformationViewController {
    func searchAndConnect() {
        connectionController.searchAndConnect { _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
            self.alertsPresenter.dismiss()
        }
    }
}

struct SetUpTapToPayInformationView: View {
    var setUpButtonAction: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil
    var learnMoreUrl: URL? = nil
    var dismiss: (() -> Void)? = nil

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var isSizeCategoryLargerThanExtraLarge: Bool {
        sizeCategory >= .accessibilityMedium
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

            Text(Localization.setUpTapToPayOnIPhoneTitle)
                .font(.title.weight(.semibold))
                .padding(32)
                .multilineTextAlignment(.center)
            Image(uiImage: .setUpBuiltInReader)
                .resizable()
                .scaledToFit()
                .frame(height: isCompact ? 80 : 206)
                .padding(.bottom, isCompact ? 16 : 32)

            PaymentSettingsFlowHint(title: Localization.hintOneTitle, text: Localization.hintOne)
            PaymentSettingsFlowHint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
            PaymentSettingsFlowHint(title: Localization.hintThreeTitle, text: Localization.hintThree)

            Spacer()

            Button(Localization.setUpButton, action: setUpButtonAction!)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 8)

            InPersonPaymentsLearnMore()
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding()
            .if(isCompact || isSizeCategoryLargerThanExtraLarge) { content in
                ScrollView(.vertical) {
                    content
                }
            }
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
        "Accept the Terms of Service during set up",
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
        "Tap to learn more about accepting payments with Tap to Pay on iPhone",
        comment: "A label prompting users to learn more about Tap to Pay on iPhone"
    )
}

struct SetUpTapToPayInformationView_Previews: PreviewProvider {
    static var previews: some View {
        SetUpTapToPayInformationView(setUpButtonAction: {})
    }
}
