import Foundation
import Combine
import Yosemite

final class SetUpTapToPayInformationViewModel: PaymentSettingsFlowPresentedViewModel, ObservableObject {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    let learnMoreURL: URL
    private let stores: StoresManager

    @Published var enableSetup: Bool = true
    @Published var setUpInProgress: Bool = false

    let siteID: Int64
    let configuration: CardPresentPaymentsConfiguration
    let connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker
    let connectivityObserver: ConnectivityObserver


    var connectionController: BuiltInCardReaderConnectionController? = nil
    var alertsPresenter: CardPresentPaymentAlertsPresenting? = nil

    private(set) var noConnectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }

    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?,
         activePaymentGateway: CardPresentPaymentsPlugin,
         connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.configuration = configuration
        self.didChangeShouldShow = didChangeShouldShow
        self.stores = stores
        self.connectionAnalyticsTracker = connectionAnalyticsTracker
        self.connectivityObserver = connectivityObserver
        self.learnMoreURL = Self.learnMoreURL(for: activePaymentGateway)

        beginConnectedReaderObservation()
        beginConnectivityObservation()
    }

    deinit {
        subscriptions.removeAll()
    }

    /// Set up to observe readers connecting / disconnecting
    ///
    private func beginConnectedReaderObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.noConnectedReader = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        stores.dispatch(connectedAction)
    }

    private func beginConnectivityObservation() {
        connectivityObserver.statusPublisher.sink { [weak self] status in
            guard let self = self else { return }
            switch (status, self.enableSetup) {
            case (.notReachable, true),
                (.reachable, false):
                self.enableSetup.toggle()
            default:
                break
            }
        }
        .store(in: &subscriptions)
    }

    func setUpTapped() {
        setUpInProgress = true
        connectionController?.searchAndConnect { _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`, so we can just
            /// dismiss the connection flow alerts.
            self.alertsPresenter?.dismiss()
            self.setUpInProgress = false
        }
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifies the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState = noConnectedReader

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }

    /// Choose learn more url based on the active Payment Gateway extension
    ///
    private static func learnMoreURL(for paymentGateway: CardPresentPaymentsPlugin) -> URL {
        switch paymentGateway {
        case .wcPay:
            return WooConstants.URLs.inPersonPaymentsLearnMoreWCPayTapToPay.asURL()
        case .stripe:
            return WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()
        }
    }
}
