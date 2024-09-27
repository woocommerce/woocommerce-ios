import Foundation
import Combine

final class RemoteBuiltInCardReaderConnectionController<AlertProvider: CardReaderConnectionAlertsProviding,
                                                        AlertPresenter: CardPresentPaymentAlertsPresenting>:
                                                    BuiltInCardReaderConnectionControlling
where AlertProvider.AlertDetails == AlertPresenter.AlertDetails {
    private var readerClient = ServiceLocator.remoteCardReaderClient
    private var cancellables = Set<AnyCancellable>()
    private let configProvider = ServiceLocator.cardReaderConfigProvider
    private let alertProvider: AlertProvider
    private let alertPresenter: AlertPresenter
    private let configuration: CardPresentPaymentsConfiguration
    private let stores: StoresManager
    private let siteID: Int64
    var connectedReaders = CurrentValueSubject<CardReader?, Never>(nil)

    init(forSiteID siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         alertsPresenter: AlertPresenter,
         alertsProvider: AlertProvider,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration) {
        self.siteID = siteID
        self.stores = stores
        self.alertProvider = alertsProvider
        self.alertPresenter = alertsPresenter
        self.configuration = configuration
    }

    func searchAndConnect(onCompletion: @escaping (Result<CardReaderConnectionResult, any Error>) -> Void) {
        readerClient.start()
        readerClient.onConnection = { [weak self] reader in
            onCompletion(.success(.connected(reader)))
            self?.connectedReaders.send(reader)
        }
        Task { [weak self] in
            await self?.connect(onCompletion: onCompletion)
        }
    }

    func connect(onCompletion: @escaping (Result<CardReaderConnectionResult, any Error>) -> Void) async {
        do {
            let locationToken = try await fetchLocationToken()
            let connectionToken = try await fetchConnectionToken()
            readerClient.connectCardReader(locationToken: locationToken, connectionToken: connectionToken)
        } catch {
            DDLogError("Remote reader connection error: \(error)")
            onCompletion(.failure(error))
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

// Usage example for iPhone (server)
class RemoteTapToPayReaderServer: ObservableObject {
    let networkingStack = NetworkingStack()

    private var cancellables = Set<AnyCancellable>()
    private let cardReaderService = ServiceLocator.cardReaderService

    var locationToken: String?
    var connectionToken: String?

    @Published var serverMessages: [String] = []

    func start() {
        serverMessages.append("Initialising Tap to Pay Server")

        networkingStack.onListenerStateUpdate = { [weak self] state in
            switch state {
            case .ready:
                self?.serverMessages.append("Server ready")
            case .failed(let error):
                self?.serverMessages.append("Server failed: \(error)")
            default:
                break
            }
        }

        networkingStack.setupServer()
        networkingStack.onMessageReceived = { [weak self] data in
            if let message = try? JSONDecoder().decode(RemoteCardReaderClientMessage.self, from: data) {
                self?.serverMessages.append("Remote reader message received: \(message)")
                self?.handleClientMessage(message)
            }
        }
        networkingStack.onConnectionStateChanged = { [weak self] isConnected in
            if !isConnected {
                self?.networkingStack.reconnect()
            }
        }
    }

    var paymentCancellable: AnyCancellable?

    func handleClientMessage(_ message: RemoteCardReaderClientMessage) {
        serverMessages.append("Received remote reader message: \(message)")
        switch message {
        case .connectReader(let locationToken, let connectionToken):
            self.locationToken = locationToken
            self.connectionToken = connectionToken
            do {
                try cardReaderService.start(self, discoveryMethod: .localMobile)
                startListeningForTapToPay { [weak self] error in
                    if case CardReaderServiceError.discovery(UnderlyingError.alreadyConnectedToReader) = error {
                        self?.serverMessages.append("Remote reader already connected")
                        self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.cardReaderConnected)
                    } else {
                        self?.serverMessages.append("Remote reader discovery error: \(error)")
                        self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.cardReaderConnectionFailed(error: error.localizedDescription))
                    }
                } onFoundTapToPayReader: { [weak self] reader in
                    guard let self else { return }
                    let connectionPublisher = cardReaderService.connect(
                        reader,
                        options: CardReaderConnectionOptions(
                            builtInOptions: .init(termsOfServiceAcceptancePermitted: true)))

                    connectionPublisher.sink(receiveCompletion: { [weak self] result in
                        self?.serverMessages.append("Remote reader connection result: \(result)")
                    }, receiveValue: { [weak self] reader in
                        self?.serverMessages.append("Remote reader connected: \(reader)")
                        self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.cardReaderConnected)
                    }).store(in: &cancellables)
                }

            } catch {
                serverMessages.append("Remote reader error: \(error)")
                networkingStack.sendMessage(RemoteCardReaderServerMessage.cardReaderConnectionFailed(error: error.localizedDescription))
            }

        case .collectPayment(let amount, let currency, let orderID):
            let metadata = PaymentIntent.initMetadata(orderID: orderID, paymentType: PaymentIntent.PaymentTypes.single)

            let parameters = PaymentParameters(amount: amount,
                                               currency: currency,
                                               stripeSmallestCurrencyUnitMultiplier: Decimal(100),
                                               paymentMethodTypes: ["card_present"],
                                               metadata: metadata)

            let readerEventsSubscription = cardReaderService.readerEvents.sink { [weak self] event in
                self?.serverMessages.append("Remote reader event: \(event)")
                self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.cardReaderMessage(event: event))
            }

            paymentCancellable = cardReaderService.capturePayment(parameters)
                .sink { [weak self] completion in
                    readerEventsSubscription.cancel()
                    if case .failure(let error) = completion {
                        self?.serverMessages.append("Remote reader payment error: \(error)")
                        self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.paymentFailed(error: error.localizedDescription))
                    }
                } receiveValue: { [weak self] paymentIntent in
                    self?.serverMessages.append("Remote reader payment intent collected: \(paymentIntent.id)")
                    self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.paymentIntentConfirmed(intent: paymentIntent, orderID: orderID))
                    self?.networkingStack.sendMessage(RemoteCardReaderServerMessage.paymentMethodCollectionSuccessful(intent: paymentIntent, orderID: orderID))
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
}

import Hardware
extension RemoteTapToPayReaderServer: CardReaderConfigProvider {
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



// Usage example for iPad (client)
class RemoteTapToPayReaderClient {
    let networkingStack = NetworkingStack()
    private let cardReaderService = ServiceLocator.cardReaderService

    var onConnection: ((CardReader) -> Void)?
    var onCardReaderMessage: ((CardReaderEvent) -> Void)?
    var onProcessingCompletion: ((PaymentIntent) -> Void)?
    var onPaymentCompletion: ((Result<PaymentIntent, Error>) -> Void)?

    func start() {
        networkingStack.startBrowsing()
        networkingStack.onEndpointsChanged = { [weak self] endpoints in
            if let firstEndpoint = endpoints.first {
                self?.networkingStack.connectToEndpoint(firstEndpoint)
            }
        }
        networkingStack.onMessageReceived = { [weak self] data in
            if let message = try? JSONDecoder().decode(RemoteCardReaderServerMessage.self, from: data) {
                self?.handleServerMessage(message)
            }
        }
        networkingStack.onConnectionStateChanged = { [weak self] isConnected in
            if !isConnected {
                self?.networkingStack.reconnect()
            }
        }
    }

    func connectCardReader(locationToken: String, connectionToken: String) {
        networkingStack.sendMessage(RemoteCardReaderClientMessage.connectReader(locationToken: locationToken,
                                                                                connectionToken: connectionToken))
    }

    func collectPayment(amount: Decimal, orderID: Int64) {
        networkingStack.sendMessage(RemoteCardReaderClientMessage.collectPayment(amount: amount, currency: "usd", orderID: orderID))
    }

    func handleServerMessage(_ message: RemoteCardReaderServerMessage) {
        switch message {
        case .cardReaderConnected:
            DDLogInfo("[Client] Remote card reader connected")
            onConnection?(
                CardReader(
                    serial: "RemoteReaderSerial",
                    vendorIdentifier: "WooRemote",
                    name: "Remote Tap to Pay",
                    status: .init(connected: true, remembered: false),
                    softwareVersion: nil,
                    batteryLevel: nil,
                    readerType: .remoteTapToPay,
                    locationId: ""))
        case .cardReaderConnectionFailed(let error):
            DDLogInfo("[Client] Remote card reader connection failed: \(error)")
        case .cardReaderMessage(let event):
            DDLogInfo("Card reader message: \(event)")
            onCardReaderMessage?(event)
        case .paymentIntentConfirmed(let intent, let orderID):
            DDLogInfo("[Client] Remote card reader payment intent confirmed. Intent: \(intent), order ID: \(orderID)")
            onProcessingCompletion?(intent)
        case .paymentMethodCollectionSuccessful(let intent, let orderID):
            DDLogInfo("[Client] Remote card reader payment success. Intent ID: \(intent.id), order ID: \(orderID)")
            onPaymentCompletion?(.success(intent))
        case .paymentFailed(let error):
            DDLogInfo("[Client] Remote payment failed: \(error)")
            onPaymentCompletion?(.failure(RemoteTapToPayServiceError.paymentFailed(details: error)))
        }
    }
}

import Yosemite

enum RemoteTapToPayServiceError: Error {
    case connectingReaderWithoutToken
    case connectingReaderWithoutLocation
    case paymentFailed(details: String)
}

import Network

// Shared message types
enum RemoteCardReaderClientMessage: Codable {
    case connectReader(locationToken: String, connectionToken: String)
    case collectPayment(amount: Decimal, currency: String, orderID: Int64)
}

enum RemoteCardReaderServerMessage: Codable {
    case cardReaderConnected
    case cardReaderConnectionFailed(error: String)
    case paymentFailed(error: String)
    case paymentIntentConfirmed(intent: PaymentIntent, orderID: Int64)
    case paymentMethodCollectionSuccessful(intent: PaymentIntent, orderID: Int64)
    case cardReaderMessage(event: CardReaderEvent)
}


// License for networking code. I've changed it some.
/**
 Copyright © 2024 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

class NetworkingStack {
    private var connection: NWConnection?
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "NetworkingQueue")

    var onMessageReceived: ((Data) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?
    var onEndpointsChanged: (([NWEndpoint]) -> Void)?

    var onListenerStateUpdate: ((NWListener.State) -> Void)?

    func setupServer(passcode: String = "1234") {
        let parameters = NWParameters.init(passcode: passcode)

        let listener = try! NWListener(using: parameters)
        listener.service = NWListener.Service(name: "CardReader", type: "_card-reader._tcp")

        listener.stateUpdateHandler = { [weak self] state in
            self?.onListenerStateUpdate?(state)
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener.start(queue: .main)
    }

    func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: "_card-reader._tcp", domain: nil), using: parameters)

        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Browser ready")
            case .failed(let error):
                print("Browser failed: \(error)")
            default:
                break
            }
        }

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            let endpoints = results.map { $0.endpoint }
            self?.onEndpointsChanged?(endpoints)
        }

        browser?.start(queue: queue)
    }

    func connectToEndpoint(_ endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: NWParameters(passcode: "1234"))
        handleConnection(connection)
    }

    private func handleConnection(_ connection: NWConnection) {
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection established")
                self?.onConnectionStateChanged?(true)
                self?.receiveMessage()
            case .failed(let error):
                print("Connection failed: \(error)")
                self?.onConnectionStateChanged?(false)
            case .waiting(let error):
                print("Connection waiting: \(error)")
            default:
                break
            }
        }

        connection.start(queue: queue)
    }

    func sendMessage<T: Codable>(_ message: T) {
        guard let data = try? JSONEncoder().encode(message) else {
            print("Failed to encode message")
            return
        }

        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            }
        })
    }

    private func receiveMessage() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content {
                self?.onMessageReceived?(data)
            }

            if let error = error {
                print("Receive error: \(error)")
            } else if isComplete {
                print("Connection closed")
                self?.onConnectionStateChanged?(false)
            } else {
                self?.receiveMessage()
            }
        }
    }

    func reconnect() {
        connection?.restart()
    }
}


/// https://developer.apple.com/documentation/Network/building-a-custom-peer-to-peer-protocol
import CryptoKit

extension NWParameters {

    // Create parameters for use in PeerConnection and PeerListener.
    convenience init(passcode: String) {
        // Customize TCP options to enable keepalives.
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        // Create parameters with custom TLS and TCP options.
        self.init(tls: NWParameters.tlsOptions(passcode: passcode), tcp: tcpOptions)

        // Enable using a peer-to-peer link.
        self.includePeerToPeer = true
    }

    // Create TLS options using a passcode to derive a preshared key.
    private static func tlsOptions(passcode: String) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()

        let authenticationKey = SymmetricKey(data: passcode.data(using: .utf8)!)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: "CardReader".data(using: .utf8)!, using: authenticationKey)

        let authenticationDispatchData = authenticationCode.withUnsafeBytes {
            DispatchData(bytes: $0)
        }

        sec_protocol_options_add_pre_shared_key(tlsOptions.securityProtocolOptions,
                                                authenticationDispatchData as __DispatchData,
                                                stringToDispatchData("CardReader")! as __DispatchData)
        sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
                                                    tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
        sec_protocol_options_set_max_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        return tlsOptions
    }

    // Create a utility function to encode strings as preshared key data.
    private static func stringToDispatchData(_ string: String) -> DispatchData? {
        guard let stringData = string.data(using: .utf8) else {
            return nil
        }
        let dispatchData = stringData.withUnsafeBytes {
            DispatchData(bytes: $0)
        }
        return dispatchData
    }
}
