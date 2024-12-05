import Testing
import Foundation
@testable import WooCommerce

struct TapToPayAwarenessMomentDeterminerTests {
    private let cardReaderSupportDeterminer: MockCardReaderSupportDeterminer
    private let cardPresentPaymentsOnboardingUseCase: MockCardPresentPaymentsOnboardingUseCase
    private let featureFlagService: MockFeatureFlagService
    private let userDefaults: MockUserDefaults
    private let sut: TapToPayAwarenessMomentDeterminer

    init() {
        cardReaderSupportDeterminer = MockCardReaderSupportDeterminer()
        cardPresentPaymentsOnboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .completed(plugin: .wcPayOnly))
        featureFlagService = MockFeatureFlagService()
        userDefaults = MockUserDefaults()

        sut = TapToPayAwarenessMomentDeterminer(cardReaderSupportDeterminer: cardReaderSupportDeterminer,
                                                cardPresentPaymentsOnboarding: cardPresentPaymentsOnboardingUseCase,
                                                featureFlagService: featureFlagService,
                                                userDefaults: userDefaults)

    }

    // MARK: - Should Present

    @Test func shouldPresent_when_featureFlagDisabled() async {
        // Given
        featureFlagService.tapToPayEducation = false

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_alreadyPresented() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = true

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_firstAttempt() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = false

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_onboardingNotCompleted() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = true
        cardPresentPaymentsOnboardingUseCase.state = .pluginNotInstalled

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_deviceNotSupportingTapToPay() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = true
        cardPresentPaymentsOnboardingUseCase.state = .completed(plugin: .wcPayOnly)
        cardReaderSupportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = false

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_siteNotSupportingTapToPay() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = true
        cardPresentPaymentsOnboardingUseCase.state = .completed(plugin: .wcPayOnly)
        cardReaderSupportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = true
        cardReaderSupportDeterminer.shouldReturnSiteSupportsLocalMobileReader = false

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_previousTapToPayUsageDetected() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = true
        cardPresentPaymentsOnboardingUseCase.state = .completed(plugin: .wcPayOnly)
        cardReaderSupportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = true
        cardReaderSupportDeterminer.shouldReturnSiteSupportsLocalMobileReader = true
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = true

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(!shouldPresent)
    }

    @Test func shouldPresent_when_noPreviousPresentation_secondAttempt_onboarded_supportsTTP() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = true
        cardPresentPaymentsOnboardingUseCase.state = .completed(plugin: .wcPayOnly)
        cardReaderSupportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = true
        cardReaderSupportDeterminer.shouldReturnSiteSupportsLocalMobileReader = true
        cardReaderSupportDeterminer.shouldReturnHasPreviousTapToPayUsage = false

        // When
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(shouldPresent)
    }

    // MARK: - Attempt

    @Test func hasFirstAttempt_when_shouldPresent() async {
        // Given
        featureFlagService.tapToPayEducation = true
        userDefaults.hasPreviousPresentation = false
        userDefaults.hasFirstAttempt = false

        // When shouldPresent called
        let shouldPresent = await sut.shouldPresent()

        // Then
        #expect(userDefaults.hasFirstAttempt)
    }
}

// MARK: - Mock User Defaults for Tap to Pay Awareness Moment Determiner

private class MockUserDefaults: UserDefaults {
    var hasPreviousPresentation: Bool = false
    var hasFirstAttempt: Bool = false

    override func bool(forKey defaultName: String) -> Bool {
        switch defaultName {
        case TapToPayAwarenessMomentDeterminer.Constants.previousPresentationKey:
            return hasPreviousPresentation
        case TapToPayAwarenessMomentDeterminer.Constants.firstAttemptKey:
            return hasFirstAttempt
        default:
            return false
        }
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        switch defaultName {
        case TapToPayAwarenessMomentDeterminer.Constants.previousPresentationKey:
            hasPreviousPresentation = value
        case TapToPayAwarenessMomentDeterminer.Constants.firstAttemptKey:
            hasFirstAttempt = value
        default:
            break
        }
    }
}
