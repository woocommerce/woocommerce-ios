import XCTest
import Combine
@testable import WooCommerce
@testable import Yosemite

final class PointOfSaleDashboardViewModelTests: XCTestCase {

    private var sut: PointOfSaleDashboardViewModel!
    private var mockConnectivityObserver: MockConnectivityObserver!

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockConnectivityObserver = MockConnectivityObserver()
        sut = PointOfSaleDashboardViewModel(connectivityObserver: mockConnectivityObserver)
        cancellables = []
    }

    override func tearDown() {
        mockConnectivityObserver = nil
        sut = nil
        cancellables = []
        super.tearDown()
    }

    func test_showsConnectivityError_when_nonReachable_then_shows_error() {
        // Given
        mockConnectivityObserver.setStatus(.notReachable)

        // Then
        XCTAssertTrue(sut.showsConnectivityError)
    }

    func test_showsConnectivityError_when_reachable_then_no_error() {
        // Given
        mockConnectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))

        // Then
        XCTAssertFalse(sut.showsConnectivityError)
    }
}
