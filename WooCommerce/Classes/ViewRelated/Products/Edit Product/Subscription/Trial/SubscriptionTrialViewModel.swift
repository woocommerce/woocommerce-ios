import Foundation
import Yosemite
import Combine

/// ViewModel for `SubscriptionTrialView`
///
final class SubscriptionTrialViewModel: ObservableObject {
    @Published var trialLength: String

    @Published var trialPeriod: SubscriptionPeriod

    @Published var isInputValid: Bool = true

    var errorMessage: String {
        String.localizedStringWithFormat(Localization.validationError,
                                         trialPeriod.freeTrialLimit,
                                         trialPeriod.descriptionPlural)
    }

    var trialPeriodDescription: String {
        switch trialLength {
        case "1":
            return trialPeriod.descriptionSingular
        default:
            return trialPeriod.descriptionPlural
        }
    }

    typealias Completion = (_ trialLength: String,
                            _ trialPeriod: SubscriptionPeriod,
                            _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    private let subscription: ProductSubscription

    /// View title
    ///
    let title = Localization.title

    init(subscription: ProductSubscription,
         completion: @escaping Completion) {
        self.subscription = subscription
        self.onCompletion = completion
        self.trialLength = subscription.trialLength
        self.trialPeriod = subscription.trialPeriod

        Publishers.CombineLatest($trialLength,
                                 $trialPeriod)
        .map { trialLength, trialPeriod in
            guard let length = Int(trialLength) else {
                return false
            }

            return length <= trialPeriod.freeTrialLimit
        }
        .assign(to: &$isInputValid)
    }

    func didTapDone() {
        onCompletion(trialLength,
                     trialPeriod,
                     hasUnsavedChanges())
    }
}

private extension SubscriptionTrialViewModel {
    func hasUnsavedChanges() -> Bool {
        if trialLength == "0" && subscription.trialLength == "0" {
            return false
        }

        return trialLength != subscription.trialLength || trialPeriod != subscription.trialPeriod
    }
}

// MARK: Constants
private extension SubscriptionTrialViewModel {
    enum Localization {
        static let title = NSLocalizedString("subscriptionTrialViewModel.title",
                                             value: "Free trial",
                                             comment: "Title for the Free trial info screen of the subscription product.")

        static let validationError = NSLocalizedString("subscriptionTrialViewModel.errorMessage",
                                             value: "The trial period cannot exceed %1$d %2$@",
                                             comment: "Validation error message in the Free trial info screen of the subscription product. " +
                                                       "Reads like: The trial period cannot exceed 90 days.")
    }
}
