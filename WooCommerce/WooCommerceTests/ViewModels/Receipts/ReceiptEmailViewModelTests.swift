import Testing
import Foundation
import Yosemite
import WooFoundation
import Combine
import WordPressShared
@testable import WooCommerce

@MainActor
struct ReceiptEmailViewModelTests {
    private let stores: MockStoresManager
    private let order: Order
    private let mocks: ReceiptEmailMocks
    private let sut: ReceiptEmailViewModel
    private var subscriptions = Set<AnyCancellable>()

    init() {
        stores = MockStoresManager(sessionManager: .testingInstance)
        order = Order.fake()
        mocks = ReceiptEmailMocks()
        sut = ReceiptEmailViewModel(
            order: order,
            stores: stores,
            emailValidator: mocks.validateEmail,
            onResult: mocks.result
        )

        // Simulate UI behavior to dismiss the view on success state
        sut.$state
            .receive(on: DispatchQueue.main)
            .filter { $0 == .success }
            .sink { [sut] _ in
                sut.onDisappear()
        }
        .store(in: &subscriptions)
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
            mocks.onResult = {
                continuation.resume(returning: $0)
            }
            sut.sendReceipt()
        }

        // Then
        #expect(completionResult == .success(order))
    }

    @Test func sendReceipt_when_action_fails() async {
        // Given send receipt action fails
        struct FakeError: Error {
            var localizedDescription: String { "Test error" }
        }
        sut.email = "test@test.com"
        stores.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .sendReceipt(_, _, onCompletion):
                onCompletion(.failure(FakeError()))
            default:
                #expect(Bool(false), "Unexpected action: \(action)")
            }
        }

        // When
        let completionResult = await withCheckedContinuation { continuation in
            mocks.onResult = {
                continuation.resume(returning: $0)
            }
            sut.sendReceipt()
        }

        // Then
        #expect(completionResult == .failure(FakeError()))
    }

    @Test func onDisappear_when_no_action() async {
        // When
        let completionResult = await withCheckedContinuation { continuation in
            mocks.onResult = {
                continuation.resume(returning: $0)
            }
            sut.onDisappear()
        }

        // Then
        #expect(completionResult == .canceled)
    }

    @Test(arguments: [true, false])
    func isEmailValid(_ validatorResult: Bool) {
        // Given
        sut.email = "test@test.com"
        var validatedEmail = ""
        mocks.emailValidator = { email in
            validatedEmail = email
            return validatorResult
        }

        // Then
        #expect(sut.isEmailValid == validatorResult)
        #expect(sut.email == validatedEmail)
    }
}

// MARK: - Helpers

private extension ReceiptEmailViewModelTests {
    private class ReceiptEmailMocks {
        var emailValidator: ((String) -> Bool) = { _ in true }
        var onResult: ((ReceiptEmailResult) -> Void) = { _ in }

        func result(_ result: ReceiptEmailResult) {
            onResult(result)
        }

        func validateEmail(_ email: String) -> Bool {
            emailValidator(email)
        }
    }
}

extension ReceiptEmailResult {
    static func ==(lhs: ReceiptEmailResult, rhs: ReceiptEmailResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            return true
        case (.failure, .failure):
            return true
        case (.canceled, .canceled):
            return true
        default:
            return false
        }
    }
}
