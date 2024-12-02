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

    var onDismiss: () -> Void

    init(flow: Flow = .onboarding,
         steps: [TapToPayEducationStepViewModel]? = nil,
         siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         cardReaderSupportDeterminer: CardReaderSupportDetermining? = nil,
         cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol? = nil,
         onDismiss: @escaping () -> Void = {}) {
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
        self.onDismiss = onDismiss
        // TODO: Inject steps
        self.steps = steps ?? [.init(
            title: "How to accept contactless card with Tap to Pay on iPhone.",
            imageName: "built-in-reader-preparing",
            descriptionSteps: [
                "Create an order on your iPhone, add products or a custom amount, "
                + "and check out with Tap to Pay on iPhone.",
                "Present your iPhone to the customer.",
                "When you see the Done checkmark, the card read is complete and the "
                + "transaction is being processed.",
                "When you see the Done checkmark, the card read."
            ]
        ),
        .init(
            title: "Accept contactless payments with only an iPhone.",
            imageName: "built-in-reader-set-up",
            descriptionSteps: [
                "With Tap to Pay on iPhone and the Woo app, you can accept in-person, "
                + "contactless payments, right on your iPhone - from physical debit and "
                + "credit cards, to Apple Pay and other digital wallets - no extra "
                + "hardware needed. It’s easy, secure, and private."
            ]
        ),
        .init(
            title: "How to handle PIN entry for a card.",
            imageName: "built-in-reader-processing",
            descriptionSteps: [
                "Customer is prompted to enter their card PIN under specific "
                + "circumstances with Tap to Pay on iPhone. For customers needing visual "
                + "or other assistance, accessibility options are accessed by selecting "
                + "‘Accessibility Options’ on the PIN screen. Audible instructions guide customers."
            ]
        )]

        reloadHasPreviousTapToPayUsage()
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

    // MARK: - Navigation

    private func nextStep() {
        if steps.count > selectedStep + 1 {
            selectedStep += 1
        }
    }

    private func previousStep() {
        if selectedStep > 0 {
            selectedStep -= 1
        }
    }

    private func skip() {
        selectedStep = steps.count - 1
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
