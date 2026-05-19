import SwiftUI
import Yosemite

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class CardReaderSettingsSearchingViewController: UIHostingController<CardReaderSettingsSearchingView>, PaymentSettingsFlowViewModelPresenter {
    /// If we know reader(s), begin search automatically once each time this VC becomes visible
    ///
    private var didBeginSearchAutomatically = false

    private var viewModel: CardReaderSettingsSearchingViewModel

    private lazy var alertsPresenter = CardPresentPaymentAlertsPresenter(rootViewController: self)

    private let alertsProvider = BluetoothReaderConnectionAlertsProvider()

    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: CardReaderConnectionController<BluetoothReaderConnectionAlertsProvider, CardPresentPaymentAlertsPresenter>? = {
        guard let knownReaderProvider = viewModel.knownReaderProvider else {
            return nil
        }

        return CardReaderConnectionController(
            forSiteID: viewModel.siteID,
            knownReaderProvider: knownReaderProvider,
            alertsPresenter: alertsPresenter,
            alertsProvider: alertsProvider,
            configuration: viewModel.configuration,
            analyticsTracker: viewModel.cardReaderConnectionAnalyticsTracker
        )
    }()

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? CardReaderSettingsSearchingViewModel else {
            return nil
        }
        self.viewModel = viewModel

        super.init(rootView: CardReaderSettingsSearchingView(learnMoreURL: viewModel.learnMoreURL))
        configureView()
    }

    private func configureView() {
        rootView.connectClickAction = { [weak self] in
            self?.searchAndConnect()
        }
        rootView.showURL = { [weak self] url in
            guard let self else { return }
            WebviewHelper.launch(url, with: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        maybeBeginSearchAutomatically()
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.didUpdate = nil
        didBeginSearchAutomatically = false
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Updates
//
private extension CardReaderSettingsSearchingViewController {
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
        let noReaderConnected = viewModel.noConnectedReader == .isTrue
        guard noReaderConnected else {
            return
        }

        /// Make sure we have a known reader
        ///
        guard viewModel.hasKnownReader() else {
            return
        }

        /// Don't auto-search if reconnection was just cancelled or failed
        ///
        guard !viewModel.shouldSkipAutoSearch() else {
            return
        }

        searchAndConnect()
        didBeginSearchAutomatically = true
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsSearchingViewController {
    func searchAndConnect() {
        viewModel.clearSkipAutoSearch()
        connectionController?.searchAndConnect() { [weak self] _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
            self?.alertsPresenter.dismiss()
        }
    }
}

struct CardReaderSettingsSearchingView: View {
    var connectClickAction: (() -> Void)? = nil
    var showURL: ((URL) -> Void)? = nil
    var learnMoreURL: URL

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

            PaymentSettingsFlowHint(number: 1, text: Localization.hintOne)
            PaymentSettingsFlowHint(number: 2, text: Localization.hintTwo)
            PaymentSettingsFlowHint(number: 3, text: Localization.hintThree)

            Spacer()

            Button(Localization.connectButton, action: connectClickAction!)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 8)

            InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(
                url: learnMoreURL,
                tappedAnalyticEvent: .InPersonPayments.learnMoreTapped(source: .manageCardReader)))
            .padding(.vertical, 8)
            .customOpenURL(action: { url in
                showURL?(url)
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

    static let hintOne = NSLocalizedString(
        "Make sure card reader is charged",
        comment: "Settings > Manage Card Reader > Connect > Hint to charge card reader"
    )

    static let hintTwo = NSLocalizedString(
        "Turn card reader on and place it next to mobile device",
        comment: "Settings > Manage Card Reader > Connect > Hint to power on reader"
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

struct CardReaderSettingsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(
            connectClickAction: {},
            learnMoreURL: WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())
    }
}
