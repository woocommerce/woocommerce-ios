import Combine
import SwiftUI
import Testing
import Yosemite
@testable import PointOfSale

@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct POSPresentationLifecycleTests {
    @Test func test_payment_cover_when_presented_and_dismissed_then_preserves_payment_model() async {
        // Given
        let payments = MockPaymentService()
        var activeStates: [Bool] = []
        let presenter = UIViewController()
        let window = makeWindow(root: presenter)
        defer { window.isHidden = true }
        let pos = UIHostingController(rootView: makePOS(payments: payments) { activeStates.append($0) })
        pos.modalPresentationStyle = .fullScreen
        await present(pos, from: presenter)
        await waitUntil {
            activeStates.contains(true) && payments.readerObservationCount > 0 && payments.cancelPaymentCount > 0
        }
        // Startup cancels stale reader preparation before any presentation under test.
        let cancellationsAtStartup = payments.cancelPaymentCount
        let observationCount = payments.readerObservationCount
        let payment = UIViewController()
        payment.modalPresentationStyle = .fullScreen

        // When
        await present(payment, from: pos)
        await settle()

        // Then
        #expect(!activeStates.contains(false))
        #expect(payments.cancelPaymentCount == cancellationsAtStartup)
        await dismiss(payment)
        await settle()
        #expect(!activeStates.contains(false))
        #expect(payments.cancelPaymentCount == cancellationsAtStartup)
        #expect(payments.readerObservationCount == observationCount)
        await dismiss(pos)
        await waitUntil { payments.cancelPaymentCount > cancellationsAtStartup }
        #expect(activeStates.filter { !$0 }.count == 1)
        #expect(payments.cancelPaymentCount == cancellationsAtStartup + 1)
    }

    @Test(arguments: [false, true])
    func test_pos_dismissal_when_started_from_loading_root_then_cleans_up_once(coveredByPayment: Bool) async {
        // Given: the coordinator first presents loading content, then installs POS.
        let payments = MockPaymentService()
        var activeStates: [Bool] = []
        let presenter = UIViewController()
        let window = makeWindow(root: presenter)
        defer { window.isHidden = true }
        let pos = UIHostingController(rootView: LoadingRoot(pos: nil))
        pos.modalPresentationStyle = .fullScreen
        await present(pos, from: presenter)
        pos.rootView = LoadingRoot(pos: makePOS(payments: payments) { activeStates.append($0) })
        await waitUntil {
            activeStates.contains(true) && payments.readerObservationCount > 0 && payments.cancelPaymentCount > 0
        }
        // Startup cancels stale reader preparation before any presentation under test.
        let cancellationsAtStartup = payments.cancelPaymentCount
        if coveredByPayment {
            let payment = UIViewController()
            payment.modalPresentationStyle = .fullScreen
            await present(payment, from: pos)
        }

        // When
        await dismiss(presenter)
        await waitUntil { payments.cancelPaymentCount > cancellationsAtStartup }

        // Then
        #expect(activeStates.contains(true))
        #expect(activeStates.filter { !$0 }.count == 1)
        #expect(payments.cancelPaymentCount == cancellationsAtStartup + 1)
    }

    @Test func test_pos_dismissal_when_root_was_just_replaced_then_does_not_activate_after_exit() async {
        // Given
        let payments = MockPaymentService()
        var activeStates: [Bool] = []
        let presenter = UIViewController()
        let window = makeWindow(root: presenter)
        defer { window.isHidden = true }
        let pos = UIHostingController(rootView: LoadingRoot(pos: nil))
        pos.modalPresentationStyle = .fullScreen
        await present(pos, from: presenter)

        // When: dismiss before yielding to the newly installed view's task.
        pos.rootView = LoadingRoot(pos: makePOS(payments: payments) { activeStates.append($0) })
        await dismiss(pos)
        let statesAtDismissal = activeStates
        let observationsAtDismissal = payments.readerObservationCount
        await settle()
        await settle()

        // Then: retain the host to expose late startup work after dismissal.
        #expect(pos.presentingViewController == nil)
        #expect(activeStates == statesAtDismissal)
        #expect(activeStates.last != true)
        #expect(payments.readerObservationCount == observationsAtDismissal)
    }

    private func makePOS(payments: MockPaymentService, onActiveChange: @escaping (Bool) -> Void) -> PointOfSaleEntryPointView {
        PointOfSaleEntryPointView(
            siteID: 1,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
            popularItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
            couponProvider: PointOfSaleCouponServicePreview(),
            couponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryPreview(),
            orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryPreview(),
            orderService: POSOrderServicePreview(),
            refundsService: POSRefundsServicePreview(),
            refundSubmissionProcessor: POSNoOpRefundSubmissionProcessor(),
            onPointOfSaleModeActiveStateChange: onActiveChange,
            cardPresentPaymentService: payments,
            receiptService: POSReceiptServicePreview(),
            pluginsService: PluginsServicePreview(),
            settingsService: PointOfSaleSettingsServicePreview(),
            collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentPreviewAnalytics(),
            searchHistoryService: PointOfSalePreviewHistoryService(),
            barcodeScanService: PointOfSalePreviewBarcodeScanService(),
            posEligibilityChecker: MockIneligibleChecker(),
            defaultSiteName: "Test Store",
            siteSettings: [],
            grdbManager: nil,
            catalogSyncCoordinator: nil,
            isLocalCatalogEligible: false,
            receiptSettingsAdminURL: "",
            staffFetcher: MockStaffFetcher(),
            services: POSPreviewServices(),
            itemProvider: PointOfSalePreviewItemService()
        )
    }

    private struct LoadingRoot: View {
        let pos: PointOfSaleEntryPointView?

        var body: some View {
            if let pos { pos } else { Text("Loading POS") }
        }
    }

    // Avoid a second concurrent catalog load when eligibility changes during startup.
    private struct MockIneligibleChecker: POSEntryPointEligibilityCheckerProtocol {
        func checkEligibility(forceRemoteCheck: Bool) async -> POSEligibilityState {
            .ineligible(reason: .unsupportedCountry)
        }

        func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
            .ineligible(reason: .unsupportedCountry)
        }
    }

    private struct MockStaffFetcher: POSStaffFetching {
        func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] { [] }
    }

    @MainActor
    private final class MockPaymentService: CardPresentPaymentFacade {
        var cancelPaymentCount = 0
        var readerObservationCount = 0
        private let preview = CardPresentPaymentPreviewService()

        var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> { preview.paymentEventPublisher }
        var cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never> { preview.cardReaderUpdateStatePublisher }
        var readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
            readerObservationCount += 1
            return preview.readerConnectionStatusPublisher
        }

        func connectReader(using method: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
            try await preview.connectReader(using: method)
        }

        func collectPayment(for order: Order, using method: CardReaderConnectionMethod, channel: PaymentChannel) async throws -> CardPresentPaymentResult {
            try await preview.collectPayment(for: order, using: method, channel: channel)
        }

        func cancelPayment() { cancelPaymentCount += 1 }
        func cancelPayment() async throws { cancelPaymentCount += 1 }
        func disconnectReader() async {}
        func updateCardReaderSoftware() async throws {}
        func cancelReconnection() async {}
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<20 {
            if condition() { return }
            await settle()
        }
        #expect(condition())
    }

    private func settle() async { try? await Task.sleep(for: .milliseconds(50)) }

    private func makeWindow(root: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        return window
    }

    private func present(_ controller: UIViewController, from presenter: UIViewController) async {
        await withCheckedContinuation { continuation in
            presenter.present(controller, animated: false) { continuation.resume() }
        }
    }

    private func dismiss(_ controller: UIViewController) async {
        await withCheckedContinuation { continuation in
            controller.dismiss(animated: false) { continuation.resume() }
        }
    }
}
