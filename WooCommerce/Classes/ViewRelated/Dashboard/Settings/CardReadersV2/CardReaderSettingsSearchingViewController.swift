import Combine
import SwiftUI
import class Yosemite.CardReaderConnectionController

/// This view controller is used when no reader is connected. It assists
/// the merchant in connecting to a reader.
///
final class CardReaderSettingsSearchingViewController: UIHostingController<CardReaderSettingsSearchingView>, PaymentSettingsFlowViewModelPresenter {
    /// If we know reader(s), begin search automatically once each time this VC becomes visible
    ///
    private var didBeginSearchAutomatically = false

    private var viewModel: CardReaderSettingsSearchingViewModel

    private lazy var alertsPresenter: CardPresentPaymentAlertsPresenting = CardPresentPaymentAlertsPresenter(rootViewController: self)

    private let alertsProvider: BluetoothReaderConnnectionAlertsProviding = BluetoothReaderConnectionAlertsProvider()

    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: CardReaderConnectionController? = {
        guard let knownReaderProvider = viewModel.knownReaderProvider else {
            return nil
        }

        let controller = CardReaderConnectionController(
            siteID: viewModel.siteID,
            storageManager: ServiceLocator.storageManager,
            stores: ServiceLocator.stores,
            knownReaderProvider: knownReaderProvider,
            configuration: viewModel.configuration
        )
        // TODO: move to a function to declutter the lazy var code
        // TODO: figure out how to share this code with other CardReaderConnectionController use cases
        connectionUIStateSubscription = controller.$uiState
            .compactMap { $0 }
            .sink { [weak self] uiState in
                guard let self else { return }
                switch uiState {
                    case let .scanningForReader(cancel):
                        alertsPresenter.present(viewModel: alertsProvider.scanningForReader(cancel: cancel))
                    case .connectingToReader:
                        alertsPresenter.present(viewModel: alertsProvider.connectingToReader())
                    case let .foundReader(name,
                                          connect,
                                          continueSearch,
                                          cancelSearch):
                        alertsPresenter.present(
                            viewModel: alertsProvider.foundReader(
                                name: name,
                                connect: connect,
                                continueSearch: continueSearch,
                                cancelSearch: cancelSearch))
                    case let .foundSeveralReaders(readerIDs,
                                                 connect,
                                                 cancelSearch):
                        alertsPresenter.foundSeveralReaders(
                            readerIDs: readerIDs,
                            connect: connect,
                            cancelSearch: cancelSearch
                        )
                    case let .updateSeveralReadersList(readerIDs):
                        alertsPresenter.updateSeveralReadersList(readerIDs: readerIDs)
                    case let .updateInProgress(requiredUpdate,
                                               progress,
                                               cancel):
                        alertsPresenter.present(
                            viewModel: alertsProvider.updateProgress(requiredUpdate: requiredUpdate,
                                                                     progress: progress,
                                                                     cancel: cancel)
                        )
                    case let .scanningFailed(error, close):
                        alertsPresenter.present(
                            viewModel: alertsProvider.scanningFailed(error: error, close: close)
                        )
                    case .dismissed:
                        alertsPresenter.dismiss()
                    case let .connectingFailed(error, retrySearch, cancelSearch):
                        alertsPresenter.present(
                            viewModel: alertsProvider.connectingFailed(error: error,
                                                                       retrySearch: retrySearch,
                                                                       cancelSearch: cancelSearch))
                    case let .connectingFailedIncompleteAddress(adminURLForWCSettings, showIncompleteAddressErrorWithRefreshButton, retrySearch, cancelSearch):
                        alertsPresenter.present(
                            viewModel: alertsProvider.connectingFailedIncompleteAddress(
                                openWCSettings: openWCSettingsAction(adminUrl: adminURLForWCSettings, showIncompleteAddressErrorWithRefreshButton: showIncompleteAddressErrorWithRefreshButton, retrySearch: retrySearch),
                                retrySearch: retrySearch,
                                cancelSearch: cancelSearch))
                    case let .connectingFailedInvalidPostalCode(retrySearch, cancelSearch):
                        alertsPresenter.present(
                            viewModel: alertsProvider.connectingFailedInvalidPostalCode(
                                retrySearch: retrySearch,
                                cancelSearch: cancelSearch))
                    case let .connectingFailedCriticallyLowBattery(retrySearch, cancelSearch):
                        alertsPresenter.present(
                            viewModel: alertsProvider.connectingFailedCriticallyLowBattery(
                                retrySearch: retrySearch,
                                cancelSearch: cancelSearch))
                    case let .updatingFailed(tryAgain, close):
                        alertsPresenter.present(
                            viewModel: alertsProvider.updatingFailed(tryAgain: tryAgain,
                                                                     close: close))
                    case let .updatingFailedLowBattery(batteryLevel, close):
                        alertsPresenter.present(
                            viewModel: alertsProvider.updatingFailedLowBattery(batteryLevel: batteryLevel,
                                                                               close: close))
                }
            }
        return controller
    }()
    private var connectionUIStateSubscription: AnyCancellable?

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? CardReaderSettingsSearchingViewModel else {
            return nil
        }
        self.viewModel = viewModel

        super.init(rootView: CardReaderSettingsSearchingView())
        configureView()
    }

    private func configureView() {
        rootView.connectClickAction = { [weak self] in
            self?.searchAndConnect()
        }
        rootView.showURL = { [weak self] url in
            guard let self = self else { return }
            WebviewHelper.launch(url, with: self)
        }
        rootView.learnMoreUrl = viewModel.learnMoreURL
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

        searchAndConnect()
        didBeginSearchAutomatically = true
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsSearchingViewController {
    func searchAndConnect() {
        connectionController?.searchAndConnect() { [weak self] _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
            self?.alertsPresenter.dismiss()
        }
    }
}

// MARK: - WC Settings
//
private extension CardReaderSettingsSearchingViewController {
    func openWCSettingsAction(adminUrl: URL?,
                              showIncompleteAddressErrorWithRefreshButton: @escaping () -> Void,
                              retrySearch: @escaping () -> Void) -> ((UIViewController) -> Void)? {
        if let adminUrl = adminUrl {
            if let site = ServiceLocator.stores.sessionManager.defaultSite,
               site.isWordPressComStore {
                return { [weak self] viewController in
                    self?.openWCSettingsInWebview(url: adminUrl, from: viewController, retrySearch: retrySearch)
                }
            } else {
                return { _ in
                    UIApplication.shared.open(adminUrl)
                    showIncompleteAddressErrorWithRefreshButton()
                }
            }
        }
        return nil
    }
    private func openWCSettingsInWebview(url adminUrl: URL,
                                         from viewController: UIViewController,
                                         retrySearch: @escaping () -> Void) {
        let nav = NavigationView {
            AuthenticatedWebView(isPresented: .constant(true),
                                 url: adminUrl,
                                 urlToTriggerExit: nil,
                                 exitTrigger: nil)
            .navigationTitle(Localization.adminWebviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewController.dismiss(animated: true) {
                            retrySearch()
                        }
                    }, label: {
                        Text(Localization.doneButtonUpdateAddress)
                    })
                }
            }
        }
            .wooNavigationBarStyle()
        let hostingController = UIHostingController(rootView: nav)
        viewController.present(hostingController, animated: true, completion: nil)
    }
}

private extension CardReaderSettingsSearchingViewController {
    enum Localization {
        static let adminWebviewTitle = NSLocalizedString(
            "WooCommerce Settings",
            comment: "Navigation title of the webview which used by the merchant to update their store address"
        )

        static let doneButtonUpdateAddress = NSLocalizedString(
            "Done",
            comment: "The button title to indicate that the user has finished updating their store's address and is" +
            "ready to close the webview. This also tries to connect to the reader again."
        )
    }
}

struct CardReaderSettingsSearchingView: View {
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

            PaymentSettingsFlowHint(title: Localization.hintOneTitle, text: Localization.hintOne)
            PaymentSettingsFlowHint(title: Localization.hintTwoTitle, text: Localization.hintTwo)
            PaymentSettingsFlowHint(title: Localization.hintThreeTitle, text: Localization.hintThree)

            Spacer()

            Button(Localization.connectButton, action: connectClickAction!)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 8)

            InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(
                tappedAnalyticEvent: .InPersonPayments.learnMoreTapped(source: .manageCardReader)))
            .padding(.vertical, 8)
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

struct CardReaderSettingsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderSettingsSearchingView(connectClickAction: {})
    }
}
