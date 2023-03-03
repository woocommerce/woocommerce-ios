@testable import Yosemite
import Networking
import Storage
@testable import WooCommerce
import XCTest

class CardPresentPaymentsOnboardingIPPUsersRefresherTests: XCTestCase {
    private var stores: MockStoresManager!
    private var sut: CardPresentPaymentsOnboardingIPPUsersRefresher!
    private var cardPresentPaymentsOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!

    override func setUp() {
        cardPresentPaymentsOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .pluginNotInstalled)
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.sessionManager.setStoreId(123)
    }

    override func tearDown() {
        stores = nil
        sut = nil
        cardPresentPaymentsOnboardingUseCase = nil
    }

    func test_refreshIPPUsersOnboardingState_when_there_are_IPP_transactions_then_it_calls_to_refresh() {
        // Given
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadSiteHasAtLeastOneIPPTransactionFinished(_, let onCompletion):
                onCompletion(true)
            default:
                break
            }
        }

        sut = CardPresentPaymentsOnboardingIPPUsersRefresher(stores: stores,
                                                             cardPresentPaymentsOnboardingUseCase: cardPresentPaymentsOnboardingUseCase)

        // When
        sut.refreshIPPUsersOnboardingState()

        // Then
        XCTAssertTrue(cardPresentPaymentsOnboardingUseCase.refreshWasCalled)
    }

    func test_refreshIPPUsersOnboardingState_when_there_are_no_IPP_transactions_then_it_does_not_call_to_refresh() {
        // Given
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadSiteHasAtLeastOneIPPTransactionFinished(_, let onCompletion):
                onCompletion(false)
            default:
                break
            }
        }
        sut = CardPresentPaymentsOnboardingIPPUsersRefresher(stores: stores,
                                                             cardPresentPaymentsOnboardingUseCase: cardPresentPaymentsOnboardingUseCase)

        // When
        sut.refreshIPPUsersOnboardingState()

        // Then
        XCTAssertFalse(cardPresentPaymentsOnboardingUseCase.refreshWasCalled)
    }
}
