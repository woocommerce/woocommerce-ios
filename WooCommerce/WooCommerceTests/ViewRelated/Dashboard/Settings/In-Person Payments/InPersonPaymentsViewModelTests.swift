import XCTest
import Combine
@testable import WooCommerce
import Yosemite

final class InPersonPaymentsViewModelTests: XCTestCase {
    private var sut: InPersonPaymentsViewModel!
    private var onboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!
    private var stateSubject: CurrentValueSubject<CardPresentPaymentOnboardingState, Never>!

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        stateSubject = CurrentValueSubject<CardPresentPaymentOnboardingState, Never>(.loading)
        onboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(
            initial: .noConnectionError,
            publisher: stateSubject.eraseToAnyPublisher())
        sut = InPersonPaymentsViewModel(useCase: onboardingUseCase)
    }

    override func tearDown() {
        _ = cancellables.map { $0.cancel() }
        cancellables = []
    }

    func test_when_created_shouldShow_isUnknown() {
        // Given, When
        // `setUp` has created the `sut`

        // Then
        assertEqual(.isUnknown, sut.shouldShow)
    }

    func test_when_onboarding_state_changes_to_loading_shouldShow_isTrue() {
        // Given
        waitFor { [weak self] promise in
            guard let self = self else { return }
            /// When the View Model receives an _onboarding_ state, it debounces, so goes async.
            /// Waiting for the View Model's state to change at the end of this means we're done with
            /// the shouldShow changes too. We ignore the first state, as it comes from `sut.init`
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.loading)
        }

        // Then
        assertEqual(.isTrue, sut.shouldShow)
    }

    func test_when_onboarding_state_changes_to_loading_didChangeShouldShow_is_called_with_newShouldShow_isTrue() {
        // Given
        let receivedShouldShow = waitFor { [weak self] promise in
            guard let self = self else { return }
            self.sut.didChangeShouldShow = { newShouldShow in
                promise(newShouldShow)
            }

            // When
            self.stateSubject.send(.loading)
        }

        // Then
        assertEqual(.isTrue, receivedShouldShow)
    }

    func test_when_onboarding_state_changes_to_completed_shouldShow_isFalse() {
        // Given
        waitFor { [weak self] promise in
            guard let self = self else { return }
            /// When the View Model receives an _onboarding_ state, it debounces, so goes async.
            /// Waiting for the View Model's state to change at the end of this means we're done with
            /// the shouldShow changes too. We ignore the first state, as it comes from `sut.init`
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.completed(plugin: .wcPayOnly))
        }

        // Then
        assertEqual(.isFalse, sut.shouldShow)
    }

    func test_when_onboarding_state_changes_to_completed_didChangeShouldShow_is_called_with_newShouldShow_isFalse() {
        // Given
        let receivedShouldShow = waitFor { [weak self] promise in
            guard let self = self else { return }
            self.sut.didChangeShouldShow = { newShouldShow in
                promise(newShouldShow)
            }

            // When
            self.stateSubject.send(.completed(plugin: .stripeOnly))
        }

        // Then
        assertEqual(.isFalse, receivedShouldShow)
    }

    func test_when_onboarding_state_changes_to_error_shouldShow_isTrue() {
        // Given
        waitFor { [weak self] promise in
            guard let self = self else { return }
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.pluginNotInstalled)
        }

        // Then
        assertEqual(.isTrue, sut.shouldShow)
    }

    func test_when_onboarding_state_changes_to_error_didChangeShouldShow_is_called_with_newShouldShow_isTrue() {
        // Given
        let receivedShouldShow = waitFor { [weak self] promise in
            guard let self = self else { return }
            self.sut.didChangeShouldShow = { newShouldShow in
                promise(newShouldShow)
            }

            // When
            self.stateSubject.send(.stripeAccountPendingRequirement(plugin: .wcPay, deadline: nil))
        }

        // Then
        assertEqual(.isTrue, receivedShouldShow)
    }

    func test_when_onboarding_state_changes_to_completed_after_an_error_didChangeShouldShow_is_called_with_newShouldShow_isFalse() {
        // Given
        stateSubject.send(.noConnectionError)

        let receivedShouldShow = waitFor { [weak self] promise in
            guard let self = self else { return }
            self.sut.didChangeShouldShow = { newShouldShow in
                promise(newShouldShow)
            }

            // When
            self.stateSubject.send(.completed(plugin: .stripeOnly))
        }

        // Then
        assertEqual(.isFalse, receivedShouldShow)
    }
}
