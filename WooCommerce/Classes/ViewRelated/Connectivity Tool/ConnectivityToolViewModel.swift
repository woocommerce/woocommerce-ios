import Foundation
import Combine
import Networking
import Yosemite

final class ConnectivityToolViewModel {

    /// Cards to be rendered by the view.
    ///
    @Published var cards: [ConnectivityTool.Card] = []

    /// Remote used to check the connection to WPCom servers.
    ///
    private let announcementsRemote: AnnouncementsRemote

    /// Remote used to check the connection to the site.
    ///
    private let systemStatusRemote: SystemStatusRemote

    /// Remote used to check the site orders.
    ///
    private let orderRemote: OrdersRemote?

    /// Site to be tested.
    ///
    private let siteID: Int64

    init(session: SessionManagerProtocol = ServiceLocator.stores.sessionManager) {

        let network = AlamofireNetwork(credentials: session.defaultCredentials)
        self.announcementsRemote = AnnouncementsRemote(network: network)
        self.systemStatusRemote = SystemStatusRemote(network: network)
        self.orderRemote = OrdersRemote(network: network)
        self.siteID = session.defaultStoreID ?? .zero

        Task {
            await startConnectivityTest()
        }
    }

    /// Sequentially runs all connectivity tests defined in `ConnectivityTest`.
    /// Provide a `sinceTest` parameter to omit test cases before it..
    ///
    private func startConnectivityTest(sinceTest: ConnectivityTest = .internetConnection) async {

        for (index, testCase) in ConnectivityTest.allCases.enumerated().dropFirst(sinceTest.rawValue) {

            // Add an inProgress card for the current test.
            cards.append(testCase.inProgressCard)

            // Start time snapshot
            let startTime = Date()

            // Run the test.
            let testResult = await runTest(for: testCase)

            // Time taken snapshot
            let timeTaken = Date().timeIntervalSince(startTime)

            // Update the test card with the test result.
            cards[index] = cards[index].updatingState(testResult)

            // Track test result
            trackResponseEvent(for: testCase, success: testResult.isSuccess, timeTaken: timeTaken)

            // Only continue with another test if the current test was successful.
            if !testResult.isSuccess {
                return // Exit connectivity test.
            }
        }

        // Add no connections issues card if all tests are successful.
        cards.append(noConnectionsIssueState())
    }

    /// Perform the test for a provided test case.
    ///
    private func runTest(for connectivityTest: ConnectivityTest) async -> ConnectivityToolCard.State {
        switch connectivityTest {
        case .internetConnection:
            return await testInternetConnectivity()
        case .wpComServers:
            return await testWPComServersConnectivity()
        case .site:
            return await testSiteConnectivity()
        case .siteOrders:
            return await testFetchingOrders()

        }
    }

    /// Retries the last test case and the subsequent ones.
    ///
    private func retryLastTest() {
        // Remove the last test
        cards.removeLast()

        // Make sure there is a test case to run.
        guard let testCaseToRepeat = ConnectivityTest(rawValue: cards.count) else {
            return
        }

        // Run tests again from the last one.
        Task {
            await startConnectivityTest(sinceTest: testCaseToRepeat)
        }
    }

    /// Perform internet connectivity case using the `connectivityObserver`.
    ///
    private func testInternetConnectivity() async -> ConnectivityToolCard.State {

        let status = ServiceLocator.connectivityObserver.currentStatus
        let reachable = {
            if case .reachable = status {
                DDLogInfo("Connectivity Tool: ✅ Internet Connection")
                return true
            } else {
                DDLogError("Connectivity Tool: ❌ Internet Connection")
                return false
            }
        }()

        let state: ConnectivityToolCard.State = reachable ?
            .success :
            .error(NSLocalizedString("It looks like you're not connected to the internet.\n\n" +
                                     "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                                     comment: "Message when there is no internet connection in the recovery tool"), [self.retryAction()])

        return state
    }

    /// Test WPCom connectivity by fetching the mobile announcements.
    ///
    func testWPComServersConnectivity() async -> ConnectivityToolCard.State {
        await withCheckedContinuation { continuation in
            announcementsRemote.loadAnnouncements(appVersion: UserAgent.bundleShortVersion, locale: Locale.current.identifier) { result in

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ WPCom connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ WPCom connection\n\(error)")
                }

                let state: ConnectivityToolCard.State = result.isSuccess ?
                    .success :
                    .error(NSLocalizedString("We can’t connect to WordPress.com right now.\n\n" +
                                             "Try again in a few minutes, or contact our support team and we will happily assist you.",
                                             comment: "Message when we can't reach WPCom in the recovery tool"), [self.retryAction()])
                continuation.resume(returning: state)
            }
        }
    }

    /// Test Site connectivity by fetching the status report..
    ///
    func testSiteConnectivity() async -> ConnectivityToolCard.State {
        await withCheckedContinuation { continuation in
            systemStatusRemote.fetchSystemStatusReport(for: siteID) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ Site connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ Site connection\n\(error)")
                }

                let state = self.stateForSiteResult(result)
                continuation.resume(returning: state)
            }
        }
    }

    /// Test fetching the site orders by actually fetching orders.
    ///
    func testFetchingOrders() async -> ConnectivityToolCard.State {
        await withCheckedContinuation { continuation in
            orderRemote?.loadAllOrders(for: siteID) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ Site Orders")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ Site Orders\n\(error)")
                }

                let state = self.stateForSiteResult(result)
                continuation.resume(returning: state)
            }
        }
    }

    private func stateForSiteResult<T>(_ result: Result<T, Error>) -> ConnectivityToolCard.State {
        guard case let .failure(error) = result else {
            return .success
        }

        let message: String
        let readMoreAction: ConnectivityToolCard.State.Action
        let readMore = NSLocalizedString("Read more", comment: "Action button title for a generic error on the connectivity tool")
        let generalTroubleshootAction = {
            UIApplication.shared.open(WooConstants.URLs.troubleshootErrorLoadingData.asURL())
            ServiceLocator.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }
        let jetpackTroubleshootAction = {
            UIApplication.shared.open(WooConstants.URLs.troubleshootJetpackConnection.asURL())
            ServiceLocator.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }

        // Handle all types of errors but timeouts are specific.
        switch (error, error.isTimeoutError) {
        case (_, true):
            message = NSLocalizedString("Your site is taking too long to respond.\n\nPlease contact your hosting provider for further assistance.",
                                        comment: "Message when we there is a timeout error in the recovery tool")
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: generalTroubleshootAction)
        case (is DecodingError, _):
            message = NSLocalizedString("We can't work properly with your site's response.\n\n" +
                                        "Read more about it or contact our support team and we will happily assist you.",
                                        comment: "Message when we there is a decoding error in the recovery tool")
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: generalTroubleshootAction)
        case (DotcomError.jetpackNotConnected, _):
            message = NSLocalizedString("There is problem with your jetpack connection.\n\n" +
                                        "Read more about it or contact our support team and we will happily assist you.",
                                        comment: "Message when we there is a jetpack error in the recovery tool")
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: jetpackTroubleshootAction)
        default:
            message = NSLocalizedString("There seems to be a problem with your site.\n\nPlease contact your hosting provider for further assistance.",
                                        comment: "Message when we there is a generic error in the recovery tool")
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: generalTroubleshootAction)
        }

        return .error(message, [readMoreAction, retryAction()])
    }

    private func retryAction() -> ConnectivityToolCard.State.Action {
        let retryText = NSLocalizedString("Retry connection", comment: "Retry connection button in the connectivity tool screen")
        return .init(title: retryText, systemImage: SystemImages.retry.rawValue, action: { [weak self] in
            self?.retryLastTest()
        })
    }

    /// Tracks the event with the respective test response.
    ///
    private func trackResponseEvent(for test: ConnectivityToolViewModel.ConnectivityTest, success: Bool, timeTaken: Double) {
        let eventTest: WooAnalyticsEvent.ConnectivityTool.Test = {
            switch test {
            case .internetConnection: return .internet
            case .wpComServers: return .wpCom
            case .site: return .site
            case .siteOrders: return .orders
            }
        }()
        ServiceLocator.analytics.track(event: .ConnectivityTool.requestResponse(test: eventTest, success: success, timeTaken: timeTaken))
    }

    private func noConnectionsIssueState() -> ConnectivityTool.Card {
        .init(title: NSLocalizedString("No connection issues", comment: "Title for when there are no connection issues in the connectivity tool screen"),
              icon: .empty,
              state: .empty(NSLocalizedString("If your data still isn’t loading, contact our support team for assistance.",
                                              comment: "Info message when there are no connection issues in the connectivity tool screen")))
    }
}

private extension ConnectivityToolViewModel {

    private enum SystemImages: String {
        case retry = "arrow.clockwise"
        case readMore = "arrow.up.forward.app"
    }

    enum ConnectivityTest: Int, CaseIterable {
        case internetConnection
        case wpComServers
        case site
        case siteOrders

        var title: String {
            switch self {
            case .internetConnection:
                NSLocalizedString("Internet Connection", comment: "Title for the internet connection connectivity tool card")
            case .wpComServers:
                NSLocalizedString("Connecting to WordPress.com Servers", comment: "Title for the WPCom servers connectivity tool card")
            case .site:
                NSLocalizedString("Connecting to your site", comment: "Title for the Your Site connectivity tool card")
            case .siteOrders:
                NSLocalizedString("Fetching your site orders", comment: "Title for the Your Site Orders connectivity tool card")
            }
        }

        var icon: ConnectivityToolCard.Icon {
            switch self {
            case .internetConnection:
                    .system("wifi")
            case .wpComServers:
                    .system("server.rack")
            case .site:
                    .system("storefront")
            case .siteOrders:
                    .system("list.clipboard")
            }
        }

        var inProgressCard: ConnectivityTool.Card {
            .init(title: title, icon: icon, state: .inProgress)
        }
    }
}

extension ConnectivityTool.Card {

    /// Updates a card state to a new given state.
    ///
    func updatingState(_ newState: ConnectivityToolCard.State) -> ConnectivityTool.Card {
        Self.init(title: title, icon: icon, state: newState)
    }
}
