import Foundation
import WooFoundation
import Yosemite

struct TapToPayEducationStepsFactory {
    static func steps(configuration: CardPresentPaymentsConfiguration) -> [TapToPayEducationStepViewModel] {
        switch configuration.countryCode {
        case .US:
            return createUS()
        case .GB:
            return createGB(configuration: configuration)
        default:
            return createUS()
        }
    }

    // MARK: - US

    private static func createUS() -> [TapToPayEducationStepViewModel] {
        [
            .init(title: Localization.Intro.title,
                  imageName: "tap-to-pay-education-intro-us",
                  description: Localization.Intro.description),
            .init(title: Localization.ContactlessCard.title,
                  imageName: "tap-to-pay-education-contactless-cards-us",
                  descriptionSteps: Localization.ContactlessCard.descriptionSteps)
        ]
    }

    // MARK: - GB

    private static func createGB(configuration: CardPresentPaymentsConfiguration) -> [TapToPayEducationStepViewModel] {
        [
            .init(title: Localization.Intro.title,
                  imageName: "tap-to-pay-education-intro-gb",
                  description: Localization.Intro.description,
                  limit: .init(configuration: configuration)),
            .init(title: Localization.ContactlessCard.title,
                  imageName: "tap-to-pay-education-contactless-cards-gb",
                  descriptionSteps: Localization.ContactlessCard.descriptionSteps),
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

    enum ContactlessCard {
        static let title = NSLocalizedString(
            "tapToPay.education.step.contactlessCard.title",
            value: "How to accept contactless card with Tap to Pay on iPhone.",
            comment: "Title for the 'How to accept contactless card' Tap to Pay merchant education"
        )

        static let descriptionSteps: [String] = [
            NSLocalizedString(
                "tapToPay.education.step.contactlessCard.descriptionStep1",
                value: "Create an order on your iPhone, add products or a custom amount, and check out with Tap to Pay on iPhone.",
                comment: "First description step for the 'How to accept contactless card' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.contactlessCard.descriptionStep2",
                value: "Present your iPhone to the customer.",
                comment: "Second description step for the 'How to accept contactless card' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.contactlessCard.descriptionStep3",
                value: "Your customer holds their card horizontally at the top of your iPhone, over the contactless symbol.",
                comment: "Third description step for the 'How to accept contactless card' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.contactlessCard.descriptionStep4",
                value: "When you see the Done checkmark, the card read is complete and the transaction is being processed.",
                comment: "Fourth description step for the 'How to accept contactless card' Tap to Pay merchant education"
            )
        ]

    }
}
