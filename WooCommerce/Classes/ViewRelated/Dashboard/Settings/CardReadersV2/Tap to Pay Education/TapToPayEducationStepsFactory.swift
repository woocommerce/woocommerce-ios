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
                  descriptionSteps: Localization.ContactlessCard.descriptionSteps),
            .init(title: Localization.ApplePay.title,
                  imageName: "tap-to-pay-education-apple-pay-us",
                  descriptionSteps: Localization.ApplePay.descriptionSteps)
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
            .init(title: Localization.ApplePay.title,
                  imageName: "tap-to-pay-education-apple-pay-gb",
                  descriptionSteps: Localization.ApplePay.descriptionSteps),
            .init(title: Localization.PIN.title,
                  imageName: "tap-to-pay-education-pin-gb",
                  description: Localization.PIN.description),
            .init(title: Localization.FallbackPaymentMethod.title,
                  imageName: "tap-to-pay-education-fallback-payment-method-gb",
                  description: Localization.FallbackPaymentMethod.description),
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

    enum ApplePay {
        static let title = NSLocalizedString(
            "tapToPay.education.step.applePay.title",
            value: "How to accept Apple Pay and other digital wallets with Tap to Pay on iPhone.",
            comment: "Title for the 'How to accept Apple Pay' Tap to Pay merchant education"
        )

        static let descriptionSteps: [String] = [
            NSLocalizedString(
                "tapToPay.education.step.applePay.descriptionStep1",
                value: "Create an order on your iPhone, add products or a custom amount, and check out with Tap to Pay on iPhone.",
                comment: "First description step for the 'How to accept Apple Pay' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.applePay.descriptionStep2",
                value: "Present your iPhone to the customer.",
                comment: "Second description step for the 'How to accept Apple Pay' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.applePay.descriptionStep3",
                value: "Your customer holds their device near your iPhone, over the contactless symbol.",
                comment: "Third description step for the 'How to accept Apple Pay' Tap to Pay merchant education"
            ),
            NSLocalizedString(
                "tapToPay.education.step.applePay.descriptionStep4",
                value: "When you see the Done checkmark, the card read is complete and the transaction is being processed.",
                comment: "Fourth description step for the 'How to accept Apple Pay' Tap to Pay merchant education"
            )
        ]
    }

    enum PIN {
        static let title = NSLocalizedString(
            "tapToPay.education.step.pin.title",
            value: "How to handle PIN entry for a card.",
            comment: "Title for the 'PIN entry' Tap to Pay merchant education step"
        )

        static let description = NSLocalizedString(
            "tapToPay.education.step.pin.description",
            value: "Customers are prompted to enter their card PIN under specific circumstances with Tap to Pay on iPhone.\n\n" +
                   "For customers needing visual or other assistance, accessibility options are accessed by selecting " +
                   "‘Accessibility Options’ on the PIN screen. Audible instructions guide customers to draw their PIN on the " +
                   "screen or tap the screen to indicate each digit - tapping once for 1, twice for 2, and so on. " +
                   "To submit their PIN, they simply swipe right with two fingers.",
            comment: "Instructions for customers using accessibility options during PIN entry with Tap to Pay on iPhone." +
                     "Describes how to use audible guidance for drawing or tapping the PIN digits and the gesture to submit."
        )
    }

    enum FallbackPaymentMethod {
        static let title = NSLocalizedString(
            "tapToPay.education.step.fallbackMethod.title",
            value: "How to accept an alternative payment method.",
            comment: "Title for the 'Fallback payment method' Tap to Pay merchant education step"
        )

        static let description = NSLocalizedString(
            "tapToPay.education.step.fallbackMethod.description",
            value: "Some cards are not able to complete contactless transactions using a PIN, which can result in payment failure.\n\n" +
                   "Ask the customer if they have another contactless card or digital wallet and select Try Collecting Again to " +
                   "continue the transaction using Tap to Pay on iPhone.\n\nOtherwise, select Try Another Payment Method and choose a " +
                   "supported alternative, such as Cash, Share Payment Link, Cash Reader, or Scan to Pay.",
            comment: "Message displayed when a contactless transaction fails due to PIN issues. Provides steps to retry using " +
                     "another contactless payment method or alternative payment options."
        )
    }
}
