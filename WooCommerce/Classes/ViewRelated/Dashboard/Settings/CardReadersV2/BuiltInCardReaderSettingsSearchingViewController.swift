import SwiftUI

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class BuiltInCardReaderSettingsSearchingViewController: UIHostingController<BuiltInCardReaderSettingsSearchingView>, CardReaderSettingsViewModelPresenter {
    /// If we know reader(s), begin search automatically once each time this VC becomes visible
    ///
    private var didBeginSearchAutomatically = false

    private var viewModel: BuiltInCardReaderSettingsSearchingViewModel?

    private lazy var alertsPresenter: CardPresentPaymentAlertsPresenter = CardPresentPaymentAlertsPresenter(rootViewController: self)

    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: BuiltInCardReaderConnectionController? = {
        guard let viewModel = viewModel else {
            return nil
        }
        return BuiltInCardReaderConnectionController(
            forSiteID: viewModel.siteID,
            alertsPresenter: alertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: viewModel.configuration,
            analyticsTracker: viewModel.cardReaderConnectionAnalyticsTracker
        )
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BuiltInCardReaderSettingsSearchingView())
        rootView.connectClickAction = {
            self.searchAndConnect()
        }
        rootView.showURL = {url in
            WebviewHelper.launch(url, with: self)
        }
    }

    /// Accept our viewmodel and listen for changes on it
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? BuiltInCardReaderSettingsSearchingViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsSearchingViewModel")
            return
        }

        rootView.learnMoreUrl = self.viewModel?.learnMoreURL
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        didBeginSearchAutomatically = false
        super.viewWillDisappear(animated)
    }
}

// MARK: - Convenience Methods
//
private extension BuiltInCardReaderSettingsSearchingViewController {
    func searchAndConnect() {
        connectionController?.searchAndConnect() { result in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
            ///
            self.alertsPresenter.dismiss()
        }
    }
}

struct BuiltInCardReaderSettingsSearchingView: View {
    var connectClickAction: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil
    var learnMoreUrl: URL? = nil

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var isSizeCategoryLargeThanExtraLarge: Bool {
        sizeCategory >= .accessibilityMedium
    }

    var body: some View {
        VStack {
            Spacer()

            Text(Localization.connectYourCardReaderTitle)
                .font(.headline)
                .padding(.bottom, isCompact ? 16 : 32)
            Image(uiImage: .preparingBuiltInReader)
                .resizable()
                .scaledToFit()
                .frame(height: isCompact ? 80 : 206)
                .padding(.bottom, isCompact ? 16 : 32)

            Hint(title: Localization.hintOneTitle, text: Localization.hintOne)
            Hint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
            Hint(title: Localization.hintThreeTitle, text: Localization.hintThree)

            Spacer()

            Button(Localization.connectButton, action: connectClickAction!)
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
            .if(isCompact || isSizeCategoryLargeThanExtraLarge) {content in
                ScrollView(.vertical) {
                    content
                }
            }
    }
}

private struct Hint: View {
    let title: String
    let text: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .padding(.all, 12)
                .background(Color(UIColor.systemGray6))
                .clipShape(Circle())
            Text(text)
                .font(.callout)
                .padding(.leading, 16)
            Spacer()
        }
            .padding(.horizontal, 8)
    }
}

// MARK: - Localization
//
private enum Localization {
    static let connectYourCardReaderTitle = NSLocalizedString(
        "Set up Tap to Pay on iPhone",
        comment: "Settings > Tap to Pay on iPhone > Prompt user to set up Tap to Pay on iPhone"
    )

    static let hintOneTitle = NSLocalizedString(
        "1",
        comment: "Settings > Tap to Pay on iPhone > Set up > Help hint number 1"
    )

    static let hintOne = NSLocalizedString(
        "Make sure your phone is signed in to iCloud and has a passcode",
        comment: "Settings > Tap to Pay on iPhone > Set up > Hint on phone requirements"
    )

    static let hintTwoTitle = NSLocalizedString(
        "2",
        comment: "Settings > Tap to Pay on iPhone > Set up > Help hint number 2"
    )

    static let hintTwo = NSLocalizedString(
        "Accept the Terms of Service when you first set up Tap to Pay on iPhone",
        comment: "Settings > Tap to Pay on iPhone > Set up > Hint about Terms of Service"
    )

    static let hintThreeTitle = NSLocalizedString(
        "3",
        comment: "Settings > Tap to Pay on iPhone > Set up > Help hint number 3"
    )

    static let hintThree = NSLocalizedString(
        "Try a payment using your card (and refund it when you're done)",
        comment: "Settings > Tap to Pay on iPhone > Set up > Hint to try a payment"
    )

    static let connectButton = NSLocalizedString(
        "Set up Tap to Pay on iPhone",
        comment: "Settings > Tap to Pay on iPhone > Set up > A button to begin setup"
    )

    static let learnMore = NSLocalizedString(
        "Tap to learn more about accepting payments using Tap to Pay on iPhone",
        comment: "A label prompting users to learn more about Tap to Pay on iPhone"
    )
}

struct BuiltInCardReaderSettingsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(connectClickAction: {})
    }
}
