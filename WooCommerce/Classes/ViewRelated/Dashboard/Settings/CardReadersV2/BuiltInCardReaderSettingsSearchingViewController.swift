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

        self.viewModel?.didUpdate = onViewModelDidUpdate

        rootView.learnMoreUrl = self.viewModel?.learnMoreURL
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        maybeBeginSearchAutomatically()
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        didBeginSearchAutomatically = false
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Updates
//
private extension BuiltInCardReaderSettingsSearchingViewController {
    func onViewModelDidUpdate() {
        maybeBeginSearchAutomatically()
    }

    func maybeBeginSearchAutomatically() {
        /// If we've already begun search automattically since this view appeared, don't do it again
        ///
        guard !didBeginSearchAutomatically else {
            return
        }

        /// Make sure there is no reader connected
        ///
        let noReaderConnected = viewModel?.noConnectedReader == .isTrue
        guard noReaderConnected else {
            return
        }

        /// Make sure we have a known reader
        ///
        guard let hasKnownReader = viewModel?.hasKnownReader(), hasKnownReader else {
            return
        }

        searchAndConnect()
        didBeginSearchAutomatically = true
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
            Image(uiImage: .cardReaderConnect)
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
    static let title = NSLocalizedString(
        "Manage Card Reader",
        comment: "Settings > Manage Card Reader > Title for the no-reader-connected screen in settings."
    )

    static let connectYourCardReaderTitle = NSLocalizedString(
        "Connect your card reader",
        comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
    )

    static let hintOneTitle = NSLocalizedString(
        "1",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 1"
    )

    static let hintOne = NSLocalizedString(
        "Make sure card reader is charged",
        comment: "Settings > Manage Card Reader > Connect > Hint to charge card reader"
    )

    static let hintTwoTitle = NSLocalizedString(
        "2",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 2"
    )

    static let hintTwo = NSLocalizedString(
        "Turn card reader on and place it next to mobile device",
        comment: "Settings > Manage Card Reader > Connect > Hint to power on reader"
    )

    static let hintThreeTitle = NSLocalizedString(
        "3",
        comment: "Settings > Manage Card Reader > Connect > Help hint number 3"
    )

    static let hintThree = NSLocalizedString(
        "Turn mobile device Bluetooth on",
        comment: "Settings > Manage Card Reader > Connect > Hint to enable Bluetooth"
    )

    static let connectButton = NSLocalizedString(
        "Connect Card Reader",
        comment: "Settings > Manage Card Reader > Connect > A button to begin a search for a reader"
    )

    static let learnMore = NSLocalizedString(
        "Tap to learn more about accepting payments with your mobile device and ordering card readers",
        comment: "A label prompting users to learn more about card readers"
    )
}

struct BuiltInCardReaderSettingsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(connectClickAction: {})
    }
}
