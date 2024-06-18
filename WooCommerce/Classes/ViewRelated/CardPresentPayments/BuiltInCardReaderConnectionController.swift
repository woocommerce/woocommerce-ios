import Combine
import Foundation
import UIKit
import Storage
import SwiftUI
import Yosemite

/// Facilitates connecting to a card reader
///
@MainActor
protocol BuiltInCardReaderConnectionControlling {
    func searchAndConnect(onCompletion: @escaping (Result<CardReaderConnectionResult, Error>) -> Void)
}

final class BuiltInCardReaderConnectionController<AlertProvider: CardReaderConnectionAlertsProviding,
                                                  AlertPresenter: CardPresentPaymentAlertsPresenting>:
                                                    BuiltInCardReaderConnectionControlling
where AlertProvider.AlertDetails == AlertPresenter.AlertDetails {
    private enum ControllerState {
        /// Initial state of the controller
        ///
        case idle

        /// Initializing (fetching payment gateway accounts)
        ///
        case initializing

        /// Preparing for search
        ///
        case preparingForSearch

        /// Begin search for card readers
        ///
        case beginSearch

        /// Searching for a card reader
        ///
        case searching

        /// Attempting to connect to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `True` result if successful, after which the view controller
        /// passed to `searchAndConnect` will be dereferenced and the state set to `idle`
        ///
        case connectToReader

        /// A failure occurred while connecting. The search may continue or be canceled. At this time we
        /// do not present the detailed error from the service.
        ///
        case connectingFailed(Error)

        /// A mandatory update is being installed
        ///
        case updating(progress: Float)

        /// User chose to retry the connection to the card reader. Starts the search again, by dismissing modals and initializing from scratch
        ///
        case retry

        /// User cancelled search/connecting to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `False` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case cancel(WooAnalyticsEvent.InPersonPayments.CancellationSource)

        /// A failure occurred. The completion passed to `searchAndConnect`
        /// will be called with a `failure` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case discoveryFailed(Error)
    }

    private let storageManager: StorageManagerType
    private let stores: StoresManager

    private var state: ControllerState {
        didSet {
            didSetState()
        }
    }

    private let siteID: Int64
    private let alertsPresenter: AlertPresenter
    private let configuration: CardPresentPaymentsConfiguration

    private let alertsProvider: AlertProvider

    /// The reader we want the user to consider connecting to
    ///
    private var candidateReader: CardReader?

    /// Tracks analytics for card reader connection events
    ///
    private let analyticsTracker: CardReaderConnectionAnalyticsTracker

    private var softwareUpdateCancelable: FallibleCancelable? = nil

    private var subscriptions = Set<AnyCancellable>()

    private var onCompletion: ((Result<CardReaderConnectionResult, Error>) -> Void)?

    private(set) lazy var dataSource: CardReaderSettingsDataSource = {
        return CardReaderSettingsDataSource(siteID: siteID, storageManager: storageManager)
    }()

    /// Gateway ID to include in tracks events
    private var gatewayID: String? {
        didSet {
            didSetGatewayID()
            analyticsTracker.setGatewayID(gatewayID: gatewayID)
        }
    }

    private var allowTermsOfServiceAcceptance: Bool

    init(
        forSiteID: Int64,
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores,
        alertsPresenter: AlertPresenter,
        alertsProvider: AlertProvider,
        configuration: CardPresentPaymentsConfiguration,
        analyticsTracker: CardReaderConnectionAnalyticsTracker,
        allowTermsOfServiceAcceptance: Bool = true
    ) {
        siteID = forSiteID
        self.storageManager = storageManager
        self.stores = stores
        state = .idle
        self.alertsPresenter = alertsPresenter
        self.alertsProvider = alertsProvider
        self.configuration = configuration
        self.analyticsTracker = analyticsTracker
        self.allowTermsOfServiceAcceptance = allowTermsOfServiceAcceptance

        configureResultsControllers()
    }

    deinit {
        subscriptions.removeAll()
    }

    func searchAndConnect(onCompletion: @escaping (Result<CardReaderConnectionResult, Error>) -> Void) {
        Task { @MainActor [weak self] in
            self?.onCompletion = onCompletion
            guard case .idle = self?.state else {
                return
            }
            self?.state = .initializing
        }
    }
}

private extension BuiltInCardReaderConnectionController {
    func configureResultsControllers() {
        dataSource.configureResultsControllers(onReload: { [weak self] in
            guard let self = self else { return }
            self.gatewayID = self.dataSource.cardPresentPaymentGatewayID()
        })
        // Sets gateway ID from initial fetch.
        gatewayID = dataSource.cardPresentPaymentGatewayID()
    }

    func didSetState() {
        switch state {
        case .idle:
            onIdle()
        case .initializing:
            onInitialization()
        case .preparingForSearch:
            onPreparingForSearch()
        case .beginSearch:
            onBeginSearch()
        case .searching:
            onSearching()
        case .retry:
            onRetry()
        case .cancel(let cancellationSource):
            onCancel(from: cancellationSource)
        case .connectToReader:
            onConnectToReader()
        case .connectingFailed(let error):
            onConnectingFailed(error: error)
        case .discoveryFailed(let error):
            onDiscoveryFailed(error: error)
        case .updating(progress: let progress):
            onUpdateProgress(progress: progress)
        }
    }

    /// Once the gatewayID arrives (during initialization) it is OK to proceed with search preparations
    ///
    func didSetGatewayID() {
        if case .initializing = state {
            state = .preparingForSearch
        }
    }

    /// Initial state of the controller
    ///
    func onIdle() {
    }

    /// Searching for a reader is about to begin. Wait, if needed, for the gateway ID to be provided from the FRC
    ///
    func onInitialization() {
        if gatewayID != nil {
            state = .preparingForSearch
        }
    }

    /// In preparation for search, sets everything to defaults
    /// Does NOT open any modal
    /// Transitions state to `.beginSearch`
    ///
    func onPreparingForSearch() {
        /// Always start fresh
        ///
        candidateReader = nil

        if case .preparingForSearch = state {
            state = .beginSearch
        }
    }

    /// Begins the search for a card reader
    /// Does NOT open any modal
    /// Transitions state to `.searching`
    /// Later, when a reader is found, state transitions to `.connectToReader`
    ///
    func onBeginSearch() {
        self.state = .searching

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            discoveryMethod: .localMobile,
            onReaderDiscovered: { [weak self] cardReaders in
                guard let self = self else {
                    return
                }

                /// Note: This completion will be called repeatedly as the list of readers
                /// discovered changes, so some care around state must be taken here.
                ///

                /// To avoid interrupting connecting to a known reader, ensure we are
                /// in the searching state before proceeding further
                ///
                guard case .searching = self.state else {
                    return
                }

                /// If we have a found reader, advance to `connectToReader`
                ///
                if cardReaders.isNotEmpty {
                    self.candidateReader = cardReaders.first
                    self.state = .connectToReader
                    return
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }

                self.analyticsTracker.discoveryFailed(error: error)
                self.state = .discoveryFailed(error)
            })

        stores.dispatch(action)
    }

    /// Opens the scanning for reader modal
    /// If the user cancels the modal will trigger a transition to `.endSearch`
    ///
    func onSearching() {
        /// Display the single view and ask the merchant if they'd
        /// like to connect to it
        ///
        if candidateReader != nil {
            self.state = .connectToReader
            return
        }

        /// If all else fails, display the "scanning" modal and
        /// stay in this state
        ///
        alertsPresenter.present(viewModel: alertsProvider.scanningForReader(cancel: {
            self.state = .cancel(.searchingForReader)
        }))
    }

    /// A mandatory update is being installed
    ///
    func onUpdateProgress(progress: Float) {
        let cancel = softwareUpdateCancelable.map { cancelable in
            return { [weak self] in
                guard let self = self else { return }
                self.state = .cancel(.searchingForReader)
                self.analyticsTracker.cardReaderSoftwareUpdateCancelTapped()
                cancelable.cancel { [weak self] result in
                    if case .failure(let error) = result {
                        DDLogError("💳 Error: canceling software update \(error)")
                    } else {
                        self?.analyticsTracker.cardReaderSoftwareUpdateCanceled()
                    }
                }
            }
        }

        alertsPresenter.present(
            viewModel: alertsProvider.updateProgress(requiredUpdate: true,
                                                     progress: progress,
                                                     cancel: cancel))
    }

    /// Retry a search for a card reader
    ///
    func onRetry() {
        alertsPresenter.dismiss()
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            self?.state = .beginSearch
        }
        stores.dispatch(action)
    }

    /// End the search for a card reader
    ///
    func onCancel(from cancellationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            self?.returnSuccess(result: .canceled(cancellationSource))
        }
        stores.dispatch(action)
    }

    /// Connect to the candidate card reader
    ///
    func onConnectToReader() {
        guard let candidateReader = candidateReader else {
            return
        }

        analyticsTracker.setCandidateReader(candidateReader)

        let softwareUpdateAction = CardPresentPaymentAction.observeCardReaderUpdateState { [weak self] softwareUpdateEvents in
            guard let self = self else { return }

            softwareUpdateEvents
                .subscribe(on: DispatchQueue.main)
                .sink { [weak self] event in
                guard let self = self else { return }

                switch event {
                case .started(cancelable: let cancelable):
                    self.softwareUpdateCancelable = cancelable
                    self.state = .updating(progress: 0)
                case .installing(progress: let progress):
                    if progress >= 0.995 {
                        self.softwareUpdateCancelable = nil
                    }
                    self.state = .updating(progress: progress)
                case .completed:
                    self.softwareUpdateCancelable = nil
                    self.state = .updating(progress: 1)
                default:
                    break
                }
            }
            .store(in: &self.subscriptions)
        }
        stores.dispatch(softwareUpdateAction)
        let options = CardReaderConnectionOptions(
            builtInOptions: BuiltInCardReaderConnectionOptions(termsOfServiceAcceptancePermitted: allowTermsOfServiceAcceptance))

        let action = CardPresentPaymentAction.connect(reader: candidateReader, options: options) { [weak self] result in
            guard let self = self else { return }

            self.analyticsTracker.setCandidateReader(nil)

            switch result {
            case .success(let reader):
                self.analyticsTracker.connectionSuccess(batteryLevel: reader.batteryLevel,
                                                        cardReaderModel: reader.readerType.model)
                // If we were installing a software update, introduce a small delay so the user can
                // actually see a success message showing the installation was complete
                if case .updating(progress: 1) = self.state {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.returnSuccess(result: .connected(reader))
                    }
                } else {
                    self.returnSuccess(result: .connected(reader))
                }
            case .failure(let error):
                // The TOS acceptance flow happens during connection, not discovery, and cancelations from Apple's
                // screen are returned as failures here.
                if case .connection(.appleBuiltInReaderTOSAcceptanceCanceled) = error as? CardReaderServiceError {
                    return self.state = .cancel(.appleTOSAcceptance)
                } else {
                    self.analyticsTracker.connectionFailed(error: error,
                                                           cardReaderModel: candidateReader.readerType.model)

                    self.state = .connectingFailed(error)
                }
            }
        }
        stores.dispatch(action)

        alertsPresenter.present(viewModel: alertsProvider.connectingToReader())
    }

    /// An error occurred while connecting
    ///
    private func onConnectingFailed(error: Error) {
        /// Clear our candidateReader to avoid connecting to a reader that isn't
        /// there while we wait for `onReaderDiscovered` to receive an update.
        /// See also https://github.com/stripe/stripe-terminal-ios/issues/104#issuecomment-916285167
        ///
        self.candidateReader = nil

        if case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: _) = error,
           underlyingError.isSoftwareUpdateError {
            return onUpdateFailed(error: error)
        }
        showConnectionFailed(error: error)
    }

    private func onUpdateFailed(error: Error) {
        guard case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: _) = error else {
            return
        }

        // Duplication of `readerSoftwareUpdateFailedBatteryLow` and `default is left to make factoring out easier later on.
        switch underlyingError {
        case .readerSoftwareUpdateFailedInterrupted:
            // Update was cancelled, don't treat this as an error
            return
        case .readerSoftwareUpdateFailedBatteryLow:
            alertsPresenter.present(
                viewModel: alertsProvider.updatingFailed(tryAgain: nil,
                                                         close: {
                    self.state = .searching
                }))
        default:
            alertsPresenter.present(
                viewModel: alertsProvider.updatingFailed(tryAgain: nil,
                                                         close: {
                    self.state = .searching
                }))
        }
    }

    private func showConnectionFailed(error: Error) {
        defer {
            // N.B. this may cause issues with retry. It was added to allow a connection controller to be reused after a
            // failure to automatically reconnect Tap to Pay on foreground. I'm fairly confident that it won't,
            // but if you're seeing problems with retry, this could be the cause.
            self.state = .idle
        }

        let retrySearch = {
            self.state = .retry
        }

        let cancelSearch = {
            self.state = .cancel(.connectionError)
        }

        guard case CardReaderServiceError.connection(let underlyingError) = error else {
            return alertsPresenter.present(
                viewModel: alertsProvider.connectingFailed(error: error,
                                                           retrySearch: retrySearch,
                                                           cancelSearch: cancelSearch))
        }

        switch underlyingError {
        case .incompleteStoreAddress(let adminUrl):
            alertsPresenter.present(
                viewModel: alertsProvider.connectingFailedIncompleteAddress(
                    wcSettingsAdminURL: adminUrl,
                    openWCSettings: openWCSettingsAction(adminUrl: adminUrl,
                                                         retrySearch: retrySearch),
                    retrySearch: retrySearch,
                    cancelSearch: cancelSearch))
        case .invalidPostalCode:
            alertsPresenter.present(
                viewModel: alertsProvider.connectingFailedInvalidPostalCode(
                    retrySearch: retrySearch,
                    cancelSearch: cancelSearch))
        default:
            if underlyingError.canBeResolvedByRetrying {
                alertsPresenter.present(
                    viewModel: alertsProvider.connectingFailed(
                        error: error,
                        retrySearch: retrySearch,
                        cancelSearch: cancelSearch))
            } else {
                alertsPresenter.present(
                    viewModel: alertsProvider.connectingFailedNonRetryable(error: error,
                                                                           close: cancelSearch))
            }
        }
    }

    private func openWCSettingsAction(adminUrl: URL?,
                                      retrySearch: @escaping () -> Void) -> (() -> Void)? {
        if let adminUrl = adminUrl {
            if let site = stores.sessionManager.defaultSite,
               site.isWordPressComStore {
                return { [weak self] in
                    self?.alertsPresenter.presentWCSettingsWebView(adminURL: adminUrl, completion: retrySearch)
                }
            } else {
                return { [weak self] in
                    UIApplication.shared.open(adminUrl)
                    self?.showIncompleteAddressErrorWithRefreshButton()
                }
            }
        }
        return nil
    }

    private func showIncompleteAddressErrorWithRefreshButton() {
        showConnectionFailed(error: CardReaderServiceError.connection(underlyingError: .incompleteStoreAddress(adminUrl: nil)))
    }

    /// An error occurred during discovery
    /// Presents the error in a modal
    ///
    private func onDiscoveryFailed(error: Error) {
        alertsPresenter.present(
            viewModel: alertsProvider.scanningFailed(error: error) { [weak self] in
            self?.returnFailure(error: error)
        })
    }

    /// Calls the completion with a success result
    ///
    private func returnSuccess(result: CardReaderConnectionResult) {
        onCompletion?(.success(result))
        state = .idle
    }

    /// Calls the completion with a failure result
    ///
    private func returnFailure(error: Error) {
        onCompletion?(.failure(error))
        state = .idle
    }
}

private extension CardReaderServiceUnderlyingError {
    var canBeResolvedByRetrying: Bool {
        switch self {
        case .appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn,
                .passcodeNotEnabled,
                .appleBuiltInReaderDeviceBanned,
                .appleBuiltInReaderMerchantBlocked,
                .nfcDisabled,
                .unsupportedMobileDeviceConfiguration:
            return false
        default:
            return true
        }
    }
}
