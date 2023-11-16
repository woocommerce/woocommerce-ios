import Foundation
import Yosemite
import Combine

/// ViewModel for `SubscriptionTrialView`
///
final class SubscriptionTrialViewModel: ObservableObject {
    @Published var trialLength: String

    @Published var trialPeriod: SubscriptionPeriod

    @Published var isInputValid: Bool = true

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

            switch trialPeriod {
            case .day:
                return length <= 90
            case .week:
                return length <= 52
            case .month:
                return length <= 24
            case .year:
                return length <= 5
            }
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
        trialLength != subscription.trialLength || trialPeriod != subscription.trialPeriod
    }
}

// MARK: Constants
private extension SubscriptionTrialViewModel {
    enum Localization {
        static let title = NSLocalizedString("Free trial", comment: "Title for the Free trial info screen of the subscription product.")
    }
}
