import XCTest
import TestKit

@testable import Yosemite
@testable import Networking

final class JustInTimeMessageStoreTests: XCTestCase {

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    var sut: JustInTimeMessageStore!

    override func setUp() {
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        sut = JustInTimeMessageStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)
    }

    func test_loadMessage_then_it_returns_nil_upon_successful_empty_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/jitm", filename: "empty-data-array")

        // When
        let result = waitFor { promise in
            let action = JustInTimeMessageAction.loadMessage(
                siteID: self.sampleSiteID,
                screen: "my_store",
                hook: .adminNotices) { result in
                    promise(result)
                }
            self.sut.onAction(action)
        }

        // Then
        XCTAssert(result.isSuccess)
        XCTAssertNil(try result.get())
    }

    func test_loadMessage_then_it_returns_the_Just_In_Time_Message_upon_successful_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/jitm", filename: "just-in-time-message-list")

        // When
        let result = waitFor { promise in
            let action = JustInTimeMessageAction.loadMessage(
                siteID: self.sampleSiteID,
                screen: "my_store",
                hook: .adminNotices) { result in
                    promise(result)
                }
            self.sut.onAction(action)
        }

        let expectedJustInTimeMessage = YosemiteJustInTimeMessage(
            siteID: sampleSiteID,
            messageID: "woomobile_ipp_barcode_users",
            featureClass: "woomobile_ipp",
            title: "In-person card payments",
            detail: "Sell anywhere, and take card payments using a mobile card reader.",
            buttonTitle: "Purchase Card Reader",
            url: "https://woocommerce.com/products/hardware/US")

        // Then
        XCTAssert(result.isSuccess)
        let recievedMessage = try XCTUnwrap(result.get())
        assertEqual(expectedJustInTimeMessage, recievedMessage)
    }

    func test_loadMessage_then_it_returns_the_first_Just_In_Time_Message_upon_successful_response_with_multiple_jitms() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/jitm", filename: "just-in-time-message-list-multiple")

        // When
        let result = waitFor { promise in
            let action = JustInTimeMessageAction.loadMessage(
                siteID: self.sampleSiteID,
                screen: "my_store",
                hook: .adminNotices) { result in
                    promise(result)
                }
            self.sut.onAction(action)
        }

        let expectedJustInTimeMessage = YosemiteJustInTimeMessage(
            siteID: sampleSiteID,
            messageID: "woomobile_onboarding_add_product",
            featureClass: "woomobile_onboarding_products",
            title: "Add some products",
            detail: "Get started selling your products: add them easily using the Products tab",
            buttonTitle: "Add product",
            url: "woocommerce://products/add")

        // Then
        XCTAssert(result.isSuccess)
        let recievedMessage = try XCTUnwrap(result.get())
        assertEqual(expectedJustInTimeMessage, recievedMessage)
    }

    func test_loadMessage_then_it_returns_error_upon_response_error() {
        // Given a stubbed generic-error network response
        network.simulateError(requestUrlSuffix: "jetpack/v4/jitm", error: DotcomError.noRestRoute)

        // When dispatching a `loadAllInboxNotes` action
        let result = waitFor { promise in
            let action = JustInTimeMessageAction.loadMessage(
                siteID: self.sampleSiteID,
                screen: "my_store",
                hook: .adminNotices) { result in
                    promise(result)
                }
            self.sut.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssert(result.isFailure)
        guard case .failure(let error) = result,
            let error = error as? DotcomError else {
            return XCTFail("Expected error not recieved")
        }
        assertEqual(DotcomError.noRestRoute, error)
    }
}
