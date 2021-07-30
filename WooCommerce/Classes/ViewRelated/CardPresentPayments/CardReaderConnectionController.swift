import Foundation
import UIKit
import Yosemite

final class CardReaderConnectionController {
    enum ControllerState {
        case idle
        case searching
        case stoppingSearch
        case foundReader
        case connectingToReader
        case connectedToReader
        case failed(Error)
    }

    private var controllerState: ControllerState {
        didSet {
            didSetControllerState()
        }
    }
    private var fromController: UIViewController
    private var siteID: Int64
    private var foundReaders: [CardReader]

    private lazy var alerts: CardReaderSettingsAlerts = {
        CardReaderSettingsAlerts()
    }()

    // TODO - ignore store state changes while connectionState == .idle

    init(from: UIViewController, forSiteID: Int64) {
        controllerState = .idle
        fromController = from
        siteID = forSiteID
        foundReaders = []
    }

    func start() {
        // TODO check and see if we are connected and if so, set our state to .connectedToReader
        // Or, if we are not connected, kick off the search by setting our state to .searching
        controllerState = .searching
    }
}

private extension CardReaderConnectionController {
    func didSetControllerState() {
        switch controllerState {
        case .searching:
            onSearching()
        case .stoppingSearch:
            onStoppingSearch()
        case .foundReader:
            onFoundReader()
        case .connectingToReader:
            onConnectingToReader()
        case .failed(let error):
            onFailed(error: error)
        default:
            dismissAnyModal()
        }
    }

    func onSearching() {
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                self?.foundReaders = cardReaders
                self?.controllerState = .foundReader
            },
            onError: { [weak self] error in
                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
                self?.controllerState = .failed(error)
            })

        ServiceLocator.stores.dispatch(action)

        alerts.scanningForReader(from: fromController, cancel: {
            self.controllerState = .idle // TODO - transition through stop searching first
        })
    }

    private func onStoppingSearch() {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() {_ in
            self.controllerState = .idle
        }
        ServiceLocator.stores.dispatch(action)
    }

    private func onFoundReader() {
        let name = foundReaders[0].id // TODO guard count

        alerts.foundReader(
            from: fromController,
            name: name,
            connect: {
                self.controllerState = .connectingToReader
            },
            continueSearch: {
                self.controllerState = .searching
            })
    }

    private func onConnectingToReader() {
        // TODO guard count foundReader
        let action = CardPresentPaymentAction.connect(reader: foundReaders[0]) { [weak self] result in
            switch result {
            case .success(let reader):
                // TODO - reconnect this - self?.knownReadersProvider?.rememberCardReader(cardReaderID: reader.id)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
                self?.controllerState = .connectedToReader
            case .failure(let error):
                ServiceLocator.analytics.track(.cardReaderConnectionFailed, withError: error)
                self?.controllerState = .failed(error)
            }
        }
        ServiceLocator.stores.dispatch(action)
        alerts.connectingToReader(from: fromController)
    }

    private func onFailed(error: Error) {
        alerts.scanningFailed(from: fromController, error: error) { [weak self] in
            self?.controllerState = .idle
        }
    }

    private func dismissAnyModal() {
        alerts.dismiss()
    }
}
