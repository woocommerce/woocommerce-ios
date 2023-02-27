@testable import Yosemite
import Networking
import Storage
@testable import WooCommerce
import XCTest

class CardPresentPaymentsOnboardingIPPUsersRefresherTests: XCTestCase {
    private var storageManager: MockStorageManager!
    private var sut: CardPresentPaymentsOnboardingIPPUsersRefresher!
    private var cardPresentPaymentsOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!

    override func setUp() {
        cardPresentPaymentsOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .pluginNotInstalled)
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        sut = nil
        cardPresentPaymentsOnboardingUseCase = nil
    }

    func test_refreshIPPUsersOnboardingState_when_there_are_IPP_transactions_then_it_calls_to_refresh() {
        // Given
        let customField = OrderMetaData(metadataID: 1, key: "receipt_url", value: "Value")
        let order = Order.fake().copy(siteID: 3, customFields: [customField])
        let useCase = OrdersUpsertUseCase(storage: storageManager.viewStorage)

        useCase.upsert([order])

        sut = CardPresentPaymentsOnboardingIPPUsersRefresher(storageManager: storageManager,
                                                             cardPresentPaymentsOnboardingUseCase: cardPresentPaymentsOnboardingUseCase)

        // When
        sut.refreshIPPUsersOnboardingState()

        // Then
        XCTAssertTrue(cardPresentPaymentsOnboardingUseCase.refreshWasCalled)
    }

    func test_refreshIPPUsersOnboardingState_when_there_are_no_IPP_transactions_then_it_does_not_call_to_refresh() {
        // Given
        sut = CardPresentPaymentsOnboardingIPPUsersRefresher(storageManager: storageManager,
                                                             cardPresentPaymentsOnboardingUseCase: cardPresentPaymentsOnboardingUseCase)

        // When
        sut.refreshIPPUsersOnboardingState()

        // Then
        XCTAssertFalse(cardPresentPaymentsOnboardingUseCase.refreshWasCalled)
    }
}
