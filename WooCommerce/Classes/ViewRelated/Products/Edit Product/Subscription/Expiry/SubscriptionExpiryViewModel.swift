import Foundation
import Yosemite
import Combine

/// ViewModel for `SubscriptionExpiryView`
///
final class SubscriptionExpiryViewModel: ObservableObject {
    struct LengthOption: Hashable {
        let title: String
        let value: Int

        var stringValue: String {
            "\(value)"
        }
    }
    typealias Completion = (_ length: String,
                            _ hasUnsavedChanges: Bool) -> Void

    /// Selected length
    ///
    @Published var selectedLength: LengthOption

    /// Prevents the `Done` button from being enabled before changing the length
    ///
    var shouldEnableDoneButton: Bool {
        subscription.length != selectedLength.stringValue
    }

    /// Length options to select from
    ///
    let lengthOptions: [LengthOption]

    /// View title
    ///
    let title = Localization.title

    private let onCompletion: Completion
    private let subscription: ProductSubscription
    private let neverExpireOption = LengthOption(title: Localization.neverExpire,
                                                 value: 0)

    init(subscription: ProductSubscription,
         completion: @escaping Completion) {
        self.subscription = subscription
        self.onCompletion = completion

        guard let periodInterval = Int(subscription.periodInterval), periodInterval > 0 else {
            self.lengthOptions = [neverExpireOption]
            self.selectedLength = neverExpireOption
            return
        }

        /// Configure length options based on billing period and interval
        ///
        var options = [neverExpireOption]
        var selectedLength = neverExpireOption
        for i in stride(from: periodInterval, through: subscription.period.freeTrialLimit, by: periodInterval) {
            let title: String = {
                let interval = "\(i)"
                let period = i == 1 ? subscription.period.descriptionSingular : subscription.period.descriptionPlural
                return interval + " " + period
            }()

            let option = LengthOption(title: title,
                                      value: i)
            options.append(option)

            if i == Int(subscription.length) {
                selectedLength = option
            }
        }
        self.lengthOptions = options
        self.selectedLength = selectedLength
    }

    func didTapDone() {
        onCompletion(selectedLength.stringValue,
                     hasUnsavedChanges())
    }
}

private extension SubscriptionExpiryViewModel {
    func hasUnsavedChanges() -> Bool {
        selectedLength.stringValue != subscription.length
    }
}

// MARK: Constants
extension SubscriptionExpiryViewModel {
    enum Localization {
        static let title = NSLocalizedString("subscriptionExpiryView.expireAfter",
                                             value: "Subscription expiration",
                                             comment: "Title for the Subscription expire after screen of the subscription product.")

        static let neverExpire = NSLocalizedString("subscriptionExpiryView.neverExpire",
                                                   value: "Never expires",
                                                   comment: "Title for the Expire after screen of the subscription product.")
    }
}
