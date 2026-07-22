import XCTest
import Combine
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

final class CardPresentPaymentOnboardingViewModelTests: XCTestCase {
    private var sut: CardPresentPaymentsOnboardingViewModel!
    private var onboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!
    private var stateSubject: CurrentValueSubject<CardPresentPaymentOnboardingState, Never>!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        stateSubject = CurrentValueSubject<CardPresentPaymentOnboardingState, Never>(.loading)
        onboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(
            initial: .noConnectionError,
            publisher: stateSubject.eraseToAnyPublisher())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase, analytics: analytics)
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
            guard let self else { return }
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
            guard let self else { return }
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
            guard let self else { return }
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
            guard let self else { return }
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
            guard let self else { return }
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
            guard let self else { return }
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
            guard let self else { return }
            self.sut.didChangeShouldShow = { newShouldShow in
                promise(newShouldShow)
            }

            // When
            self.stateSubject.send(.completed(plugin: .stripeOnly))
        }

        // Then
        assertEqual(.isFalse, receivedShouldShow)
    }

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        // Given
        let sut = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)

        // Then
        XCTAssertPropertyCount(sut,
                               expectedCount: 11,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

    // MARK: - Analytics

    func test_when_onboarding_state_changes_to_completed_then_onboarding_completed_event_is_tracked() {
        // Given
        waitFor { [weak self] promise in
            guard let self else { return }
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.completed(plugin: .wcPayOnly))
        }

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardPresentOnboardingCompleted.rawValue))
    }

    func test_when_onboarding_state_changes_to_error_then_onboarding_not_completed_event_is_tracked_with_reason() throws {
        // Given
        waitFor { [weak self] promise in
            guard let self else { return }
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.pluginNotInstalled)
        }

        // Then
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingNotCompleted.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        assertEqual(CardPresentPaymentOnboardingState.pluginNotInstalled.reasonForAnalytics, properties["reason"] as? String)
    }

    func test_when_onboarding_state_changes_to_loading_then_no_onboarding_step_event_is_tracked() {
        // Given
        waitFor { [weak self] promise in
            guard let self else { return }
            self.sut.$state.dropFirst(1).sink { _ in
                promise(())
            }.store(in: &self.cancellables)

            // When
            self.stateSubject.send(.loading)
        }

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardPresentOnboardingCompleted.rawValue))
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardPresentOnboardingNotCompleted.rawValue))
    }

    func test_skipPendingRequirements_tracks_onboarding_step_skipped_event_with_remind_later_true() throws {
        // Given
        onboardingUseCase.state = .stripeAccountPendingRequirement(plugin: .wcPay, deadline: nil)

        // When
        sut.skipPendingRequirements()

        // Then
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingStepSkipped.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        assertEqual(true, properties["remind_later"] as? Bool)
    }

    func test_skipOverdueRequirements_tracks_onboarding_step_skipped_event_with_remind_later_false() throws {
        // Given
        onboardingUseCase.state = .stripeAccountOverdueRequirement(plugin: .wcPay)

        // When
        sut.skipOverdueRequirements()

        // Then
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingStepSkipped.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        assertEqual(false, properties["remind_later"] as? Bool)
    }

    func test_selectPlugin_tracks_gateway_selected_event_with_payment_gateway_property() throws {
        // When
        sut.selectPlugin(.wcPay)

        // Then
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentPaymentGatewaySelected.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        assertEqual(CardPresentPaymentsPlugin.wcPay.pluginName, properties["payment_gateway"] as? String)
    }
}
