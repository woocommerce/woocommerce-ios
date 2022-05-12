import XCTest
import Combine
import Yosemite
@testable import WooCommerce

final class ReceiptViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_generateContent_dispatches_ReceiptAction_and_sends_content() {
        // Given
        let viewModel = ReceiptViewModel(order: .fake(), receipt: .fake(), countryCode: "", stores: stores)
        let mockContent = "A receipt"
        stores.whenReceivingAction(ofType: ReceiptAction.self) { action in
            if case let .generateContent(_, _, onContent) = action {
                onContent(mockContent)
            }
        }

        // When
        var content: String?
        viewModel.content.sink { receiptContent in
            content = receiptContent
        }.store(in: &subscriptions)
        XCTAssertNil(content)
        viewModel.generateContent()

        // Then
        XCTAssertEqual(content, mockContent)
    }

    func test_getting_emailFormData_after_generateContent_does_not_dispatch_ReceiptAction_and_returns_latest_content() {
        // Given
        let order = Order.fake()
        let viewModel = ReceiptViewModel(order: order, receipt: .fake(), countryCode: "", stores: stores)

        let mockStoreName = "All the sweets"
        var sessionManager = stores.sessionManager
        sessionManager.defaultSite = .fake().copy(name: mockStoreName)

        let mockContent = "A receipt"
        var generateContentInvocationCount = 0
        stores.whenReceivingAction(ofType: ReceiptAction.self) { action in
            if case let .generateContent(_, _, onContent) = action {
                generateContentInvocationCount += 1
                onContent(mockContent)
            }
        }

        // When
        viewModel.generateContent()
        XCTAssertEqual(generateContentInvocationCount, 1)

        var emailFormData: CardPresentPaymentReceiptEmailCoordinator.EmailFormData?
        viewModel.emailFormData.sink { data in
            emailFormData = data
        }.store(in: &subscriptions)

        // Then
        XCTAssertEqual(emailFormData, .init(content: mockContent, order: order, storeName: mockStoreName))
        XCTAssertEqual(generateContentInvocationCount, 1)
    }
}
