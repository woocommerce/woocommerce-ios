import Foundation
import Yosemite
import Experiments

protocol TapToPayAwarenessMomentDetermining {
    func shouldPresent() async -> Bool
    func setPresented()
}

struct TapToPayAwarenessMomentDeterminer: TapToPayAwarenessMomentDetermining {
    private let cardReaderSupportDeterminer: CardReaderSupportDetermining
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let featureFlagService: FeatureFlagService

    private let userDefaults: UserDefaults

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         cardReaderSupportDeterminer: CardReaderSupportDetermining? = nil,
         cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         userDefaults: UserDefaults = .standard) {
        self.cardReaderSupportDeterminer = cardReaderSupportDeterminer ?? CardReaderSupportDeterminer(siteID: siteID, configuration: configuration)
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.featureFlagService = featureFlagService
        self.userDefaults = userDefaults
    }

    func shouldPresent() async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.tapToPayEducation) else {
            return false
        }

        guard !wasPresented() else {
            return false
        }

        // Do not present immediately after the merchant is eligible
        // Avoid cases such as a fresh login
        guard !isFirstAttempt() else {
            setAttempted()
            return false
        }

        guard case .completed = cardPresentPaymentsOnboarding.state else {
            return false
        }

        async let deviceSupportsTapToPay = cardReaderSupportDeterminer.deviceSupportsLocalMobileReader()
        async let siteSupportsTapToPay = cardReaderSupportDeterminer.siteSupportsLocalMobileReader()
        async let hasPreviousTapToPayUsage = cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
        let deviceSupportsTapToPayResult = await deviceSupportsTapToPay
        let siteSupportsTapToPayResult = await siteSupportsTapToPay
        let hasPreviousTapToPayUsageResult = await hasPreviousTapToPayUsage

        return deviceSupportsTapToPayResult && siteSupportsTapToPayResult && !hasPreviousTapToPayUsageResult
    }

    // MARK: - Previous Presentation

    func setPresented() {
        userDefaults.set(true, forKey: Constants.previousPresentationKey)
    }

    private func wasPresented() -> Bool {
        userDefaults.bool(forKey: Constants.previousPresentationKey)
    }

    // MARK: - Attempt

    private func setAttempted() {
        userDefaults.set(true, forKey: Constants.firstAttemptKey)
    }

    private func isFirstAttempt() -> Bool {
        !userDefaults.bool(forKey: Constants.firstAttemptKey)
    }
}

extension TapToPayAwarenessMomentDeterminer {
    enum Constants {
        static let previousPresentationKey = "TapToPayAwarenessMomentDeterminer.previousPresentationKey"
        static let firstAttemptKey = "TapToPayAwarenessMomentDeterminer.firstAttemptKey"
    }
}
