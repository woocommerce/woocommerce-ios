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

    private let userDefaults: UserDefaults

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         cardReaderSupportDeterminer: CardReaderSupportDetermining? = nil,
         cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol = CardPresentPaymentsOnboardingUseCase(),
         userDefaults: UserDefaults = .standard) {
        self.cardReaderSupportDeterminer = cardReaderSupportDeterminer ?? CardReaderSupportDeterminer(siteID: siteID, configuration: configuration)
        self.cardPresentPaymentsOnboarding = cardPresentPaymentsOnboarding
        self.userDefaults = userDefaults
    }

    func shouldPresent() async -> Bool {
        guard !wasPresented() else {
            return false
        }

        // Do not present immediately after the merchant is eligible
        // Avoid cases such as a fresh login
        guard !isFirstAttempt() else {
            setAttempted()
            return false
        }

        switch cardPresentPaymentsOnboarding.state {
        case .completed, .codPaymentGatewayNotSetUp:
            break
        default:
            return false
        }

        async let deviceSupportsTapToPay = cardReaderSupportDeterminer.deviceSupportsTapToPayReader()
        async let siteSupportsTapToPay = cardReaderSupportDeterminer.siteSupportsTapToPayReader()
        async let hasPreviousTapToPayUsage = cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
        let deviceSupportsTapToPayResult = await deviceSupportsTapToPay
        let siteSupportsTapToPayResult = await siteSupportsTapToPay
        let hasPreviousTapToPayUsageResult = await hasPreviousTapToPayUsage

        return deviceSupportsTapToPayResult && siteSupportsTapToPayResult && !hasPreviousTapToPayUsageResult
    }

    // MARK: - Previous Presentation

    func setPresented() {
        userDefaults.set(true, forKey: UserDefaults.Key.tapToPayAwarenessMomentPresented.rawValue)
    }

    private func wasPresented() -> Bool {
        userDefaults.bool(forKey: UserDefaults.Key.tapToPayAwarenessMomentPresented.rawValue)
    }

    // MARK: - Attempt

    private func setAttempted() {
        userDefaults.set(true, forKey: UserDefaults.Key.tapToPayAwarenessMomentFirstLaunchCompleted.rawValue)
    }

    private func isFirstAttempt() -> Bool {
        !userDefaults.bool(forKey: UserDefaults.Key.tapToPayAwarenessMomentFirstLaunchCompleted.rawValue)
    }
}
