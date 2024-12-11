import Testing
import Combine
@testable import WooCommerce

struct TapToPayEducationViewModelTests {
    private let cardReaderSupportDeterminer: MockCardReaderSupportDeterminer
    private let cardPresentPaymentsOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase

    init() {
        cardReaderSupportDeterminer = MockCardReaderSupportDeterminer()
        cardPresentPaymentsOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .completed(plugin: .wcPayOnly))
    }

    private func create(flow: TapToPayEducationViewModel.Flow,
                        steps: [TapToPayEducationStepViewModel]? = nil) -> TapToPayEducationViewModel {
        let steps = steps ?? [.init(title: "1", imageName: "", description: ""),
                              .init(title: "2", imageName: "", description: ""),
                              .init(title: "3", imageName: "", description: "")]
        return TapToPayEducationViewModel(flow: flow,
                                          steps: steps,
                                          siteID: 123,
                                          cardReaderSupportDeterminer: cardReaderSupportDeterminer,
                                          cardPresentPaymentsOnboardingUseCase: cardPresentPaymentsOnboardingUseCase)
    }

    // MARK: - Primary Action

    @Test func primaryAction_when_onboarding() {
        // Given
        let sut = create(flow: .onboarding)

        // When & Then
        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 0)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 1)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Done")
        #expect(sut.selectedStep == 2)
        sut.primaryAction.action()

        #expect(sut.dismiss)
    }

    @Test func primaryAction_when_about_and_no_previous_tap_to_pay_usage() {
        // Given
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = false
        let sut = create(flow: .about)

        // When & Then
        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 0)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 1)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Set Up Tap to Pay on iPhone")
        #expect(sut.selectedStep == 2)
        sut.primaryAction.action()

        #expect(!sut.dismiss)
        #expect(sut.showingSetUpFlow)
    }

    @Test func primaryAction_when_about_and_has_previous_tap_to_pay_usage() async throws {
        // Given
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = true
        let sut = create(flow: .about)

        var cancellables = Set<AnyCancellable>()
        await withCheckedContinuation { continuation in
            sut.$hasPreviousTapToPayUsage
                .sink { hasPreviousUsage in
                    if hasPreviousUsage {
                        continuation.resume()
                    }
                }
                .store(in: &cancellables)
        }

        // When & Then
        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 0)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Next")
        #expect(sut.selectedStep == 1)
        sut.primaryAction.action()

        #expect(sut.primaryAction.title == "Done")
        #expect(sut.selectedStep == 2)
        sut.primaryAction.action()

        #expect(sut.dismiss)
        #expect(!sut.showingSetUpFlow)
    }

    // MARK: - Secondary Action

    @Test func secondaryAction_when_onboarding() throws {
        // Given
        let sut = create(flow: .onboarding)
        try #require(sut.secondaryAction?.title == "Skip")
        try #require(sut.selectedStep == 0)

        // When Skip is tapped
        sut.secondaryAction?.action()

        // Then
        #expect(sut.secondaryAction == nil)
        #expect(sut.selectedStep == 2)
    }

    @Test func secondaryAction_when_about_and_no_previous_tap_to_pay_usage() throws {
        // Given
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = false
        let sut = create(flow: .about)
        try #require(sut.secondaryAction?.title == "Skip")
        try #require(sut.selectedStep == 0)

        // When Skip is tapped
        sut.secondaryAction?.action()

        // Then
        #expect(sut.secondaryAction?.title == "Done")
        #expect(sut.selectedStep == 2)
    }

    @Test func secondaryAction_when_about_and_has_previous_tap_to_pay_usage() async throws {
        // Given
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = true
        let sut = create(flow: .about)
        try #require(sut.secondaryAction?.title == "Skip")
        try #require(sut.selectedStep == 0)

        var cancellables = Set<AnyCancellable>()
        await withCheckedContinuation { continuation in
            sut.$hasPreviousTapToPayUsage
                .sink { hasPreviousUsage in
                    if hasPreviousUsage {
                        continuation.resume()
                    }
                }
                .store(in: &cancellables)
        }

        // When Skip is tapped
        sut.secondaryAction?.action()

        // Then
        #expect(sut.secondaryAction == nil)
        #expect(sut.selectedStep == 2)
    }

    // MARK: - Back Action

    @Test func backAction() throws {
        // Given
        let sut = create(flow: .onboarding)
        try #require(sut.backAction == nil)
        try #require(sut.selectedStep == 0)

        // When Next is tapped
        sut.primaryAction.action()
        #expect(sut.selectedStep == 1)

        // Then Back action should be available
        #expect(sut.backAction?.title == "Back")

        // When Back action is tapped
        sut.backAction?.action()

        // Then
        #expect(sut.backAction == nil)
        #expect(sut.selectedStep == 0)
    }
}
