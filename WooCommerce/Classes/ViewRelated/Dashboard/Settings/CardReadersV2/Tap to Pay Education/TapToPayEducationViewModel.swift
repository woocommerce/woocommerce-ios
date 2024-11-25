import Foundation

final class TapToPayEducationViewModel: ObservableObject {
    struct Action {
        let title: String
        let action: () -> Void
    }

    @Published var selectedStep = 0
    @Published var steps: [TapToPayEducationStepViewModel]

    var onDismiss: () -> Void = {}

    init() {
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
            return Action(title: Localization.done) { [weak self] in
                guard let self else { return }
                onDismiss()
            }
        } else {
            return Action(title: Localization.next) { [weak self] in
                guard let self else { return }
                nextStep()
            }
        }
    }

    var secondaryAction: Action? {
        guard selectedStep != steps.count - 1 else {
            return nil
        }

        return Action(title: Localization.skip) { [weak self] in
            guard let self else { return }

            selectedStep = steps.count - 1
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
}
