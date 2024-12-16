import Testing
import Foundation
import Yosemite
import WooFoundation
import Combine
@testable import WooCommerce

@MainActor
struct ReceiptEmailViewModelTests {
    private let stores: MockStoresManager
    private let order: Order
    private let noticesPresenter: MockNoticePresenter
    private let sut: ReceiptEmailViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        stores = MockStoresManager(sessionManager: .testingInstance)
        order = Order.fake()
        noticesPresenter = MockNoticePresenter()
        sut = ReceiptEmailViewModel(
            order: order,
            stores: stores,
            noticesPresenter: noticesPresenter,
            countryCode: CountryCode.US,
            cardReaderModel: "Model"
        )

        sut.$dismiss.sink { [sut] _ in
            sut.onDisappear()
        }
        .store(in: &cancellables)
    }

    @Test func sendReceipt_when_action_succeeds() async {
        // Given send receipt action succeeds
        sut.email = "test@test.com"
        stores.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .sendReceipt(order, _, onCompletion):
                onCompletion(.success(order))
            default:
                #expect(Bool(false), "Unexpected action: \(action)")
            }
        }

        // When
        let completionResult = await withCheckedContinuation { continuation in
            sut.onDismiss = {
                continuation.resume(returning: $0)
            }
            sut.sendReceipt()
        }

        // Then
        #expect(completionResult != nil)
    }

    @Test func sendReceipt_when_action_fails() async {
        // Given send receipt action fails
        sut.email = "test@test.com"
        stores.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .sendReceipt(_, _, onCompletion):
                struct FakeError: Error {
                    var localizedDescription: String { "Test error" }
                }
                onCompletion(.failure(FakeError()))
            default:
                #expect(Bool(false), "Unexpected action: \(action)")
            }
        }

        // When
        let completionResult = await withCheckedContinuation { continuation in
            noticesPresenter.onNoticeQueued = {
                continuation.resume(returning: $0)
            }
            sut.sendReceipt()
        }

        // Then
        #expect(completionResult.title != nil)
    }

    @Test(arguments: [true, false])
    func isEmailValid(_ validatorResult: Bool) {
        // Given
        sut.email = "test@test.com"
        var validatedEmail = ""
        sut.emailValidator = { email in
            validatedEmail = email
            return validatorResult
        }

        // Then
        #expect(sut.isEmailValid == validatorResult)
        #expect(sut.email == validatedEmail)
    }
}
