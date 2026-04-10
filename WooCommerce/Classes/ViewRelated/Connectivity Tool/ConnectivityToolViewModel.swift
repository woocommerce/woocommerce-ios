import Foundation
import Combine
import UIKit
import Yosemite
import enum Networking.DotcomError
import class Networking.AlamofireNetwork
import class Networking.AnnouncementsRemote
import class Networking.SystemStatusRemote
import class Networking.OrdersRemote
import class Networking.ProductsRemote
import class Networking.UserAgent

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
    private let orderRemote: OrdersRemote

    /// Remote used to check loading products
    ///
    private let productsRemote: ProductsRemote

    /// Site to be tested.
    ///
    private let siteID: Int64

    private var latestTestResult: [ConnectivityTestResult] = []

    init(session: SessionManagerProtocol = ServiceLocator.stores.sessionManager) {

        let network = AlamofireNetwork(credentials: session.defaultCredentials, selectedSite: nil, appPasswordSupportState: nil)
        self.announcementsRemote = AnnouncementsRemote(network: network)
        self.systemStatusRemote = SystemStatusRemote(network: network)
        self.orderRemote = OrdersRemote(network: network)
        self.productsRemote = ProductsRemote(network: network)
        self.siteID = session.defaultStoreID ?? .zero

        Task {
            await startConnectivityTest()
        }
    }

    /// Sequentially runs all connectivity tests defined in `ConnectivityTest`.
    /// Provide a `sinceTest` parameter to omit test cases before it..
    ///
    private func startConnectivityTest(sinceTest: ConnectivityTest = .internetConnection) async {
        let supportedTests: [ConnectivityTest] = {
            if ServiceLocator.stores.isAuthenticatedWithoutWPCom == false {
                [.internetConnection, .wpComServers, .site, .siteOrders, .loadingProducts]
            } else {
                [.internetConnection, .site, .siteOrders, .loadingProducts]
            }
        }()
        for (index, testCase) in supportedTests.enumerated().dropFirst(sinceTest.rawValue) {

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

            latestTestResult.append(ConnectivityTestResult(testCase: testCase,
                                                           result: testResult,
                                                           timeTaken: timeTaken))

            // Only continue with another test if the current test was successful.
            if !testResult.isSuccess {
                return // Exit connectivity test.
            }
        }

        // Add no connections issues card if all tests are successful.
        cards.append(noConnectionsIssueState())
    }

    /// This is not a user facing text but will be part of the Zendesk submission for troubleshooting.
    func troubleshootingDescription() -> String? {
        guard !latestTestResult.isEmpty else {
            return nil
        }

        return latestTestResult.enumerated().map { index, result in
            "## \(index + 1). " + result.description()
        }.joined()
    }

    /// Perform the test for a provided test case.
    ///
    private func runTest(for connectivityTest: ConnectivityTest) async -> ConnectivityToolCard.ConnectivityState {
        switch connectivityTest {
        case .internetConnection:
            return await testInternetConnectivity()
        case .wpComServers:
            return await testWPComServersConnectivity()
        case .site:
            return await testSiteConnectivity()
        case .siteOrders:
            return await testFetchingOrders()
        case .loadingProducts:
            return await testFetchingProducts()

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
    private func testInternetConnectivity() async -> ConnectivityToolCard.ConnectivityState {

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

        let state: ConnectivityToolCard.ConnectivityState = reachable ?
            .success :
            .error(Localization.ErrorMessage.noInternet, [self.retryAction()])

        return state
    }

    /// Test WPCom connectivity by fetching the mobile announcements.
    ///
    func testWPComServersConnectivity() async -> ConnectivityToolCard.ConnectivityState {
        await withCheckedContinuation { continuation in
            announcementsRemote.loadAnnouncements(appVersion: UserAgent.bundleShortVersion, locale: Locale.current.identifier) { result in

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ WPCom connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ WPCom connection\n\(error)")
                }

                let state: ConnectivityToolCard.ConnectivityState = result.isSuccess ?
                    .success :
                    .error(Localization.ErrorMessage.wpcomConnection, [self.retryAction()])
                continuation.resume(returning: state
                )
            }
        }
    }

    /// Test Site connectivity by fetching the status report..
    ///
    func testSiteConnectivity() async -> ConnectivityToolCard.ConnectivityState {
        await withCheckedContinuation { continuation in
            systemStatusRemote.fetchSystemStatusReport(for: siteID) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ Site connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ Site connection\n\(error)")
                }

                let state = self.stateForSiteResult(result, operation: .site)
                continuation.resume(returning: state)
            }
        }
    }

    /// Test fetching the site orders by actually fetching orders.
    ///
    func testFetchingOrders() async -> ConnectivityToolCard.ConnectivityState {
        do {
            _ = try await orderRemote.loadAllOrders(for: siteID)
            DDLogInfo("Connectivity Tool: ✅ Site Orders")
            return stateForSiteResult(Result<[Order], Error>.success([]), operation: .siteOrders)
        } catch {
            DDLogError("Connectivity Tool: ❌ Site Orders\n\(error)")
            return stateForSiteResult(Result<[Order], Error>.failure(error), operation: .siteOrders)
        }
    }

    /// Test fetching products.
    ///
    func testFetchingProducts() async -> ConnectivityToolCard.ConnectivityState {
        do {
            _ = try await productsRemote.loadAllProducts(for: siteID)
            DDLogInfo("Connectivity Tool: ✅ Retrieving products successfully")
            return stateForSiteResult(Result<[Product], Error>.success([]), operation: .loadingProducts)
        } catch {
            DDLogError("Connectivity Tool: ❌ Failed to load products\n\(error)")
            return stateForSiteResult(Result<[Product], Error>.failure(error), operation: .loadingProducts)
        }
    }

    private func stateForSiteResult<T>(_ result: Result<T, Error>, operation: ConnectivityTest) -> ConnectivityToolCard.ConnectivityState {
        guard case let .failure(error) = result else {
            return .success
        }

        let message: String
        let readMore = Localization.Action.readMore
        let generalTroubleshootAction = {
            UIApplication.shared.open(WooConstants.URLs.troubleshootErrorLoadingData.asURL())
            ServiceLocator.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }
        var readMoreAction = ConnectivityToolCard.ConnectivityState.Action(title: readMore,
                                                                           systemImage: SystemImages.readMore.rawValue,
                                                                           action: generalTroubleshootAction)
        let jetpackTroubleshootAction = {
            UIApplication.shared.open(WooConstants.URLs.troubleshootJetpackConnection.asURL())
            ServiceLocator.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }

        // Handle all types of errors but timeouts are specific.
        switch (error, error.isTimeoutError) {
        case (_, true):
            message = Localization.ErrorMessage.timeout
            return .error(message, [readMoreAction, retryAction()])

        case (let decodingError as DecodingError, _):
            message = Localization.ErrorMessage.decodingError
            let technicalDetails = formatDecodingError(decodingError, operation: operation)
            let viewDetailsTitle = Localization.Action.viewDetails
            let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: viewDetailsTitle,
                systemImage: SystemImages.viewDetails.rawValue,
                technicalDetails: technicalDetails
            )
            return .error(message, [viewDetailsAction, readMoreAction, retryAction()])

        case (DotcomError.jetpackNotConnected, _):
            message = Localization.ErrorMessage.noJetpackConnection
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: jetpackTroubleshootAction)
            return .error(message, [readMoreAction, retryAction()])

        case (let error, _):
            message = Localization.ErrorMessage.generic
            let technicalDetails = String(describing: error)
            let viewDetailsTitle = Localization.Action.viewDetails
            let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: viewDetailsTitle,
                systemImage: SystemImages.viewDetails.rawValue,
                technicalDetails: technicalDetails
            )
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: generalTroubleshootAction)
            return .error(message, [viewDetailsAction, readMoreAction, retryAction()])
        }
    }

    private func retryAction() -> ConnectivityToolCard.ConnectivityState.Action {
        let retryText = Localization.Action.retry
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
            case .loadingProducts: return .products
            }
        }()
        ServiceLocator.analytics.track(event: .ConnectivityTool.requestResponse(test: eventTest, success: success, timeTaken: timeTaken))
    }

    private func noConnectionsIssueState() -> ConnectivityTool.Card {
        .init(title: Localization.noIssues,
              icon: .empty,
              state: .empty(Localization.noIssuesMessage)
        )
    }

    /// Extracts detailed technical information from a DecodingError for debugging purposes.
    /// Contents are intentionally not localized for simplicity.
    ///
    private func formatDecodingError(_ error: DecodingError, operation: ConnectivityTest) -> String {
        var details: [String] = []

        details.append("Operation: \(operation.title)")
        details.append("Error Type: Decoding Error")
        details.append("")

        switch error {
        case .typeMismatch(let type, let context):
            details.append("Issue: Type Mismatch")
            details.append("Expected Type: \(type)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .valueNotFound(let type, let context):
            details.append("Issue: Required Value Not Found")
            details.append("Expected Type: \(type)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .keyNotFound(let key, let context):
            details.append("Issue: Required Key Not Found")
            details.append("Missing Key: \(key.stringValue)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .dataCorrupted(let context):
            details.append("Issue: Data Corrupted")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        @unknown default:
            details.append("Issue: Unknown Decoding Error")
            details.append("Description: \(error.localizedDescription)")
        }

        return details.joined(separator: "\n")
    }

    /// Formats a coding path into a readable string representation.
    ///
    private func formatCodingPath(_ codingPath: [CodingKey]) -> String {
        guard !codingPath.isEmpty else {
            return "Root level"
        }
        return codingPath.map { $0.stringValue }.joined(separator: " → ")
    }
}

fileprivate struct ConnectivityTestResult {
    let testCase: ConnectivityToolViewModel.ConnectivityTest
    let result: ConnectivityToolCard.ConnectivityState
    let timeTaken: TimeInterval

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    func description() -> String {
        let lines: [String] = [
            caseName,
            "Took: \(formattedTimeTaken)",
            "Result: \(resultDescription)",
            ""
        ]
        return lines.joined(separator: "\n")
    }

    private var formattedTimeTaken: String {
        let milliseconds = timeTaken * 1000
        return String(format: "%.0fms", milliseconds)
    }

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    private var caseName: String {
        switch testCase {
        case .internetConnection: "Internet Connection"
        case .wpComServers: "Connecting to WordPress.com Servers"
        case .site: "Connecting to your site"
        case .siteOrders: "Fetching your site orders"
        case .loadingProducts: "Fetching products in your store"
        }
    }

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    private var resultDescription: String {
        switch result {
        case .inProgress: return "In progress"
        case .success: return "Success"
        case .empty(let message): return message
        case .error(_, let actions):
            let lines = actions.compactMap { $0.technicalDetails }
            return lines.joined(separator: "\n")
        }
    }
}


private extension ConnectivityToolViewModel {
    enum Localization {
        static let noIssues = NSLocalizedString(
            "connectivityToolViewModel.message.noIssues",
            value: "No connection issues",
            comment: "Title for when there are no connection issues in the connectivity tool screen"
        )
        static let noIssuesMessage = NSLocalizedString(
            "connectivityToolViewModel.message.noIssuesMessage",
            value: "If your data still isn't loading, contact our support team for assistance.",
            comment: "Info message when there are no connection issues in the connectivity tool screen"
        )
        enum ErrorMessage {
            static let noInternet = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.noInternet",
                value: "It looks like you're not connected to the internet.\n\n" +
                "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                comment: "Message when there is no internet connection in the recovery tool"
            )
            static let wpcomConnection = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.wpcomConnection",
                value: "We can’t connect to WordPress.com right now.\n\n" +
                "Try again in a few minutes, or contact our support team and we will happily assist you.",
                comment: "Message when we can't reach WPCom in the recovery tool"
            )
            static let timeout = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.timeout",
                value: "Your site is taking too long to respond.\n\nPlease contact your hosting provider for further assistance.",
                comment: "Message when we there is a timeout error in the recovery tool"
            )
            static let decodingError = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.decodingError",
                value: "We can't work properly with your site's response.\n\n" +
                "View technical details below or contact our support team and we will happily assist you.",
                comment: "Message when we there is a decoding error in the recovery tool"
            )
            static let noJetpackConnection = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.jetpackNotConnected",
                value: "There is problem with your jetpack connection.\n\n" +
                "Read more about it or contact our support team and we will happily assist you.",
                comment: "Message when we there is a jetpack error in the recovery tool"
            )
            static let generic = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.default",
                value: "There seems to be a problem with your site.\n\nPlease contact your hosting provider for further assistance.",
                comment: "Message when we there is a generic error in the recovery tool"
            )
        }
        enum Action {
            static let readMore = NSLocalizedString(
                "connectivityToolViewModel.action.readMore",
                value: "Read more",
                comment: "Action button title for an error on the connectivity tool"
            )
            static let viewDetails = NSLocalizedString(
                "connectivityToolViewModel.action.viewTechnicalDetails",
                value: "View technical details",
                comment: "Button to view technical error details in the connectivity tool"
            )
            static let retry = NSLocalizedString(
                "connectivityToolViewModel.action.retry",
                value: "Retry test",
                comment: "Retry test button in the connectivity tool screen"
            )
        }
    }
}

private extension ConnectivityToolViewModel {

    private enum SystemImages: String {
        case retry = "arrow.clockwise"
        case readMore = "arrow.up.forward.app"
        case viewDetails = "info.circle"
    }

    enum ConnectivityTest: Int {
        case internetConnection
        case wpComServers
        case site
        case siteOrders
        case loadingProducts

        var title: String {
            switch self {
            case .internetConnection:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.internetConnection",
                    value: "Internet Connection",
                    comment: "Title for the internet connection connectivity tool card"
                )
            case .wpComServers:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.wpComServers",
                    value: "Connecting to WordPress.com Servers",
                    comment: "Title for the WPCom servers connectivity tool card"
                )
            case .site:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.site",
                    value: "Connecting to your site",
                    comment: "Title for the Your Site connectivity tool card"
                )
            case .siteOrders:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.siteOrders",
                    value: "Fetching your site orders",
                    comment: "Title for the Your Site Orders connectivity tool card"
                )
            case .loadingProducts:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.loadingProducts",
                    value: "Fetching products in your store",
                    comment: "Title for the test to load products in connectivity tool"
                )
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
            case .loadingProducts:
                    .system("cart")
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
    func updatingState(_ newState: ConnectivityToolCard.ConnectivityState) -> ConnectivityTool.Card {
        Self.init(title: title, icon: icon, state: newState)
    }
}
