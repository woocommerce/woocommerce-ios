import Foundation
import Combine

final class RemoteBuiltInCardReaderConnectionController<AlertProvider: CardReaderConnectionAlertsProviding,
                                                        AlertPresenter: CardPresentPaymentAlertsPresenting>:
                                                    BuiltInCardReaderConnectionControlling
where AlertProvider.AlertDetails == AlertPresenter.AlertDetails {
    private var multipeerSession: CardReaderMultipeerSession?
    private var cancellables = Set<AnyCancellable>()
    private let configProvider = ServiceLocator.cardReaderConfigProvider

    func searchAndConnect(onCompletion: @escaping (Result<CardReaderConnectionResult, any Error>) -> Void) {
        multipeerSession = CardReaderMultipeerSession()
        multipeerSession?.$connectedPeers
            .compactMap({ connectedPeers in
                return connectedPeers.first
            })
            .sink(receiveValue: { [weak self] peerID in
                Task { [weak self] in
                    await self?.connect(to: peerID, onCompletion: onCompletion)
                }
            })
            .store(in: &cancellables)
        multipeerSession?.startBrowsing()
    }

    func connect(to peerID: MCPeerID, onCompletion: @escaping (Result<CardReaderConnectionResult, any Error>) -> Void) async {
        do {
            let locationToken = try await fetchLocationToken()
            let connectionToken = try await fetchConnectionToken()
            let request = RemoteCardReaderRequest.connectReader(locationToken: locationToken, connectionToken: connectionToken)

            multipeerSession?.responseHandler = { [weak self] response in
                DDLogInfo("Recieved remote reader response: \(response)")
                switch response {
                case .readerConnected:
                    onCompletion(.success(.connected(.init(serial: peerID.displayName, vendorIdentifier: nil, name: "Remote iPhone", status: .init(connected: true, remembered: false), softwareVersion: nil, batteryLevel: nil, readerType: .appleBuiltIn, locationId: locationToken))))
                    let paymentRequest = RemoteCardReaderRequest.collectPayment(amount: .init(100), currency: "usd", orderID: "123")
                    self?.multipeerSession?.send(request: paymentRequest, to: peerID)
                case .readerDisconnected:
                    break
                case .errorCollectingPayment:
                    break
                case .paymentIntentConfirmed(let id, let orderID):
                    break
                }
            }
            multipeerSession?.send(request: request, to: peerID)

        } catch {
            DDLogError("Error preparing for search: \(error)")
            return
        }
    }
    // TODO: put these on ReaderLocationProvider, ReaderTokenProvider protocols
    private func fetchLocationToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            configProvider.fetchDefaultLocationID { result in
                continuation.resume(with: result)
            }
        }
    }

    private func fetchConnectionToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            configProvider.fetchToken { result in
                continuation.resume(with: result)
            }
        }
    }
}


import MultipeerConnectivity
import os

class CardReaderMultipeerSession: NSObject, ObservableObject {
    private let serviceType = "card-reader"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let log = Logger()
    private let remoteTapToPayService = RemoteTapToPayService()

    var responseHandler: ((RemoteCardReaderResponse) -> Void)?

    @Published var connectedPeers: [MCPeerID] = []

    override init() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }

    func startBrowsing() {
        serviceBrowser.startBrowsingForPeers()
    }

    func startAdvertising() {
        serviceAdvertiser.startAdvertisingPeer()
    }

    func send(request: RemoteCardReaderRequest, to peerID: MCPeerID) {
        do {
            let data = try JSONEncoder().encode(request)
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            log.error("Error sending request: \(String(describing: request)), error: \(String(describing: error))")
        }
    }

    func send(response: RemoteCardReaderResponse, to peerID: MCPeerID) {
        do {
            let data = try JSONEncoder().encode(response)
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            log.error("Error sending response: \(String(describing: response)), error: \(String(describing: error))")
        }
    }

    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
}

extension CardReaderMultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

extension CardReaderMultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

extension CardReaderMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.rawValue)")
        connectedPeers = session.connectedPeers
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        log.info("didReceive bytes \(data.count) bytes")
        if let request = try? JSONDecoder().decode(RemoteCardReaderRequest.self, from: data) {
            remoteTapToPayService.handleRequest(request: request, responseHandler: { [weak self] response in
                self?.send(response: response, to: peerID)
            })
        }

        if let response = try? JSONDecoder().decode(RemoteCardReaderResponse.self, from: data) {
            responseHandler?(response)
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}


enum RemoteCardReaderRequest: Codable {
    case connectReader(locationToken: String, connectionToken: String)
    case collectPayment(amount: Decimal, currency: String, orderID: String)
}

enum RemoteCardReaderResponse: Codable {
    case readerConnected
    case readerDisconnected
    case errorCollectingPayment
    case paymentIntentConfirmed(id: String, orderID: String)
}


import Hardware
class RemoteTapToPayService {
    private var cancellables = Set<AnyCancellable>()

    private let cardReaderService = ServiceLocator.cardReaderService

    var locationToken: String?
    var connectionToken: String?

    func handleRequest(request: RemoteCardReaderRequest, responseHandler: @escaping (RemoteCardReaderResponse) -> Void) {
        DDLogInfo("Received remote reader request: \(request)")
        switch request {
        case .connectReader(let locationToken, let connectionToken):
            self.locationToken = locationToken
            self.connectionToken = connectionToken
            do {
                try cardReaderService.start(self, discoveryMethod: .localMobile)
                startListeningForTapToPay { error in
                    DDLogError("Remote reader discovery error: \(error)")
                    responseHandler(.errorCollectingPayment)
                } onFoundTapToPayReader: { [weak self] reader in
                    guard let self else { return }
                    let connectionPublisher = cardReaderService.connect(
                        reader,
                        options: CardReaderConnectionOptions(
                            builtInOptions: .init(termsOfServiceAcceptancePermitted: true)))

                    connectionPublisher.sink(receiveCompletion: { result in
                        DDLogInfo("Remote reader connection result: \(result)")
                    }, receiveValue: { reader in
                        DDLogInfo("Remote reader connected: \(reader)")
                        responseHandler(.readerConnected)
                    }).store(in: &cancellables)
                }

            } catch {
                DDLogError("Remote reader error: \(error)")
                responseHandler(.errorCollectingPayment)
            }
        case .collectPayment(let amount, let currency, let orderID):
            let paymentPublisher = cardReaderService.capturePayment(
                PaymentIntentParameters(amount: amount,
                                        currency: currency,
                                        stripeSmallestCurrencyUnitMultiplier: Decimal(string: "100")!,
                                        paymentMethodTypes: ["card_present"]))
            paymentPublisher.sink { error in
                DDLogError("Remote reader collection error: \(error)")
                responseHandler(.errorCollectingPayment)
            } receiveValue: { paymentIntent in
                responseHandler(.paymentIntentConfirmed(id: paymentIntent.id, orderID: orderID))
            }
            .store(in: &cancellables)

            break
        }
    }
    func startListeningForTapToPay(onError: @escaping (Error) -> Void, onFoundTapToPayReader: @escaping (CardReader) -> Void) {
        cardReaderService.discoveredReaders
            .subscribe(Subscribers.Sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished: break
                    case .failure(let error):
                        onError(error)
                    }
                },
                receiveValue: { readers in
                    let supportedReaders = readers.filter({
                        $0.readerType == .appleBuiltIn
                    })
                    guard let reader = supportedReaders.first else {
                        return
                    }
                    onFoundTapToPayReader(reader)
                }
            ))
    }
}

extension RemoteTapToPayService: CardReaderConfigProvider {
    func fetchToken(completion: @escaping (Result<String, any Error>) -> Void) {
        guard let connectionToken else {
            return completion(.failure(RemoteTapToPayServiceError.connectingReaderWithoutToken))
        }
        completion(.success(connectionToken))
    }

    func fetchDefaultLocationID(completion: @escaping (Result<String, any Error>) -> Void) {
        guard let locationToken else {
            return completion(.failure(RemoteTapToPayServiceError.connectingReaderWithoutLocation))
        }
        completion(.success(locationToken))
    }
}

enum RemoteTapToPayServiceError: Error {
    case connectingReaderWithoutToken
    case connectingReaderWithoutLocation
}
