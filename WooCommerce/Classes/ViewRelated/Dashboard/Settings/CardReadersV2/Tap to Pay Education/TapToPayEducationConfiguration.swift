import Foundation
import WooFoundation

struct TapToPayEducationConfiguration {
    static func steps(for country: CountryCode) -> [TapToPayEducationStepViewModel] {
        switch country {
        case .US:
            Self.US
        case .GB:
            Self.GB
        default:
            Self.US
        }
    }

    // MARK: - US

    static var US: [TapToPayEducationStepViewModel] {
        [
            .init(title: Localization.Intro.title, imageName: "tap-to-pay-education-intro-us", description: Localization.Intro.description)
        ]
    }

    // MARK: - GB

    static var GB: [TapToPayEducationStepViewModel] {
        [
            .init(title: Localization.Intro.title, imageName: "tap-to-pay-education-intro-gb", description: Localization.Intro.description)
        ]
    }
}

// MARK: - Strings

private enum Localization {
    enum Intro {
        static let title = NSLocalizedString(
            "tapToPay.education.step.intro.title",
            value: "Accept contactless payments with only an iPhone.",
            comment: "Title for the initial Tap to Pay merchant education step"
        )

        static let description = NSLocalizedString(
            "tapToPay.education.step.intro.description",
            value: "With Tap to Pay on iPhone and the Woo app, you can accept in-person, contactless payments, " +
                   "right on your iPhone - from physical debit and credit cards, to Apple Pay and other digital " +
                   "wallets - no extra hardware needed. It’s easy, secure, and private.",
            comment: "Description for the initial Tap to Pay merchant education step. When using the name “Tap to Pay " +
                     "on iPhone” in headlines or copy, do not shorten to “Tap to Pay” or “Apple Tap to Pay. Always " +
                     "typeset “Tap to Pay on iPhone” as five words. The T and Ps should be uppercased, followed by " +
                     "lowercase letters."
        )
    }
}
