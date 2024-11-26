import Foundation
import Yosemite

final class TapToPayEducationViewModel: ObservableObject {
    struct Action {
        let title: String
        let action: () -> Void
    }

    enum Flow {
        case onboarding
        case about
    }

    @Published var selectedStep = 0
    @Published var steps: [TapToPayEducationStepViewModel]
    @Published private(set) var isInteractiveDismissDisabled = false

    @Published var showingSetUpFlow: Bool = false
    @Published private(set) var hasPreviousTapToPayUsage = false

    private let flow: Flow
    private let cardReaderSupportDeterminer: CardReaderSupportDetermining

    let configuration: CardPresentPaymentsConfiguration
    let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol
    let siteID: Int64

    var onDismiss: () -> Void = {}

    init(flow: Flow = .onboarding,
         siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         cardReaderSupportDeterminer: CardReaderSupportDetermining? = nil,
         cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol? = nil) {
        self.flow = flow
        self.cardReaderSupportDeterminer = cardReaderSupportDeterminer ?? CardReaderSupportDeterminer(siteID: siteID, configuration: configuration)
        self.siteID = siteID
        self.configuration = configuration
        if let cardPresentPaymentsOnboardingUseCase {
            self.cardPresentPaymentsOnboardingUseCase = cardPresentPaymentsOnboardingUseCase
        } else {
            let onboardingUseCase = CardPresentPaymentsOnboardingUseCase()
            self.cardPresentPaymentsOnboardingUseCase = onboardingUseCase
            self.cardPresentPaymentsOnboardingUseCase.refresh()
        }
        self.isInteractiveDismissDisabled = flow == .onboarding ? true : false

        // TODO: Inject steps
        steps = []
    }

    // MARK: - Navigation

    func nextStep() {
        if steps.count > selectedStep + 1 {
            selectedStep += 1
        }
    }

    func previousStep() {
        if selectedStep > 0 {
            selectedStep -= 1
        }
    }

    func skip() {
        selectedStep = steps.count - 1
    }

    // MARK: - Actions

    var backAction: Action? {
        guard selectedStep > 0 else {
            return nil
        }

        return Action(title: Localization.back) { [weak self] in
            guard let self else { return }

            previousStep()
        }
    }

    var primaryAction: Action {
        if selectedStep == steps.count - 1 {
            if flow == .about && !hasPreviousTapToPayUsage {
                return Action(title: Localization.setUpTapToPay) { [weak self] in
                    guard let self else { return }
                    showingSetUpFlow = true
                }
            } else {
                return Action(title: Localization.done) { [weak self] in
                    guard let self else { return }
                    onDismiss()
                }
            }
        } else {
            return Action(title: Localization.next) { [weak self] in
                guard let self else { return }
                nextStep()
            }
        }
    }

    var secondaryAction: Action? {
        if selectedStep == steps.count - 1 {
            if flow == .about, !hasPreviousTapToPayUsage {
                return Action(title: Localization.done) { [weak self] in
                    guard let self else { return }
                    onDismiss()
                }
            } else {
                return nil
            }
        } else {
            return Action(title: Localization.skip) { [weak self] in
                guard let self else { return }
                skip()
            }
        }
    }
}

extension TapToPayEducationViewModel {
    func reloadHasPreviousTapToPayUsage() {
        guard flow == .about else {
            return
        }

        Task { @MainActor in
            hasPreviousTapToPayUsage = await cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
        }
    }
}

private enum Localization {
    static let back = NSLocalizedString(
        "tapToPay.education.back",
        value: "Back",
        comment: "Text for the button to take one step back in Tap to Pay education flow"
    )

    static let skip = NSLocalizedString(
        "tapToPay.education.skip",
        value: "Skip",
        comment: "Text for the button to skip Tap to Pay education flow to the last step"
    )

    static let next = NSLocalizedString(
        "tapToPay.education.next",
        value: "Next",
        comment: "Text for the button to go to the next Tap to Pay education flow step"
    )

    static let done = NSLocalizedString(
        "tapToPay.education.done",
        value: "Done",
        comment: "Text for the button to dismiss Tap to Pay education flow"
    )

    static let setUpTapToPay = NSLocalizedString(
        "tapToPay.education.setUpTapToPay",
        value: "Set Up Tap to Pay on iPhone",
        comment: "Button title for Set up Tap to Pay button in Tap to Pay education flow. The button opens the " +
        "Set Up Tap to Pay on iPhone flow.")
}
