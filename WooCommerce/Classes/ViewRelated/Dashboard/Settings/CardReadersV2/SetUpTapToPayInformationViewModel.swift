import Foundation
import Combine
import Yosemite

final class SetUpTapToPayInformationViewModel: PaymentSettingsFlowPresentedViewModel, ObservableObject {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    private(set) var learnMoreURL: URL
    var dismiss: (() -> Void)?

    private let stores: StoresManager

    @Published private(set) var enableSetup: Bool = true
    @Published private(set) var setUpInProgress: Bool = false

    let siteID: Int64
    let configuration: CardPresentPaymentsConfiguration
    let connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker
    let connectivityObserver: ConnectivityObserver

    private let onboardingStatePublisher: Published<CardPresentPaymentOnboardingState>.Publisher
    private let analytics: Analytics = ServiceLocator.analytics

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
         onboardingStatePublisher: Published<CardPresentPaymentOnboardingState>.Publisher,
         connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.configuration = configuration
        self.didChangeShouldShow = didChangeShouldShow
        self.stores = stores
        self.connectionAnalyticsTracker = connectionAnalyticsTracker
        self.connectivityObserver = connectivityObserver
        self.onboardingStatePublisher = onboardingStatePublisher
        self.learnMoreURL = Self.learnMoreURL(for: .wcPay) // this will be updated when the onboarding state is known

        beginOnboardingStateObservation()
        beginConnectedReaderObservation()
        beginConnectivityObservation()
    }

    deinit {
        subscriptions.removeAll()
    }

    // this is only used for the learn more url...
    private func beginOnboardingStateObservation() {
        self.onboardingStatePublisher.share().sink { [weak self] onboardingState in
            guard case .completed(let plugin) = onboardingState else {
                return
            }
            self?.learnMoreURL = Self.learnMoreURL(for: plugin.preferred)
        }.store(in: &subscriptions)
    }

    /// Set up to observe readers connecting / disconnecting
    ///
    private func beginConnectedReaderObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.disconnectFromBluetoothReader(in: readers)
            self.noConnectedReader = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        stores.dispatch(connectedAction)
    }

    /// This screen is only used for setting up the Built In card reader.
    /// If we're connected to a Bluetooth reader when the screen opens,
    /// we should disconnect, as we can't continue with setup while connected.
    private func disconnectFromBluetoothReader(in readers: [CardReader]) {
        if readers.includesBluetoothReader() {
            self.connectionAnalyticsTracker.automaticallyDisconnectedFromReader()
            self.disconnect()
        }
    }

    private func disconnect() {
        let action = CardPresentPaymentAction.disconnect { _ in }
        stores.dispatch(action)
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
        analytics.track(.tapToPaySetupInformationSetUpTapped)
        setUpInProgress = true
        connectionController?.searchAndConnect { [weak self] _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`, so we can just
            /// dismiss the connection flow alerts.
            self?.alertsPresenter?.dismiss()
            self?.setUpInProgress = false
        }
    }

    func cancelTapped() {
        analytics.track(.tapToPaySetupInformationCancelTapped)
        dismiss?()
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

private extension [CardReader] {
    func includesBluetoothReader() -> Bool {
        return self.first(where: { reader in
            switch reader.readerType {
            case .appleBuiltIn:
                return false
            default:
                return true
            }
        }) != nil
    }
}
