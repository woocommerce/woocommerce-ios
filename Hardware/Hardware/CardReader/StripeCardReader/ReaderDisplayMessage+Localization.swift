#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension ReaderDisplayMessage {
    var localizedMessage: String {
        switch self {
        case .retryCard:
            return Localization.retryCard
        case .insertCard:
            return Localization.insertCard
        case .insertOrSwipeCard:
            return Localization.insertOrSwipeCard
        case .multipleContactlessCardsDetected:
            return Localization.multipleContactlessCards
        case .removeCard:
            return Localization.removeCard
        case .swipeCard:
            return Localization.swipeCard
        case .tryAnotherCard:
            return Localization.tryAnotherCard
        case .tryAnotherReadMethod:
            return Localization.tryAnotherReadMethod
        @unknown default:
            DDLogWarn("Unlocalized IPP ReaderDisplayMessage recieved")
            return Terminal.stringFromReaderDisplayMessage(self)
        }
    }

    enum Localization {
        /// Strings from `Terminal.stringFromReaderDisplayMessage`
        static let retryCard = NSLocalizedString(
            "Retry Card",
            comment: "Message from the in-person payment card reader prompting user to retry payment with their card")
        static let insertCard = NSLocalizedString(
            "Insert Card",
            comment: "Message from the in-person payment card reader prompting user to insert their card")
        static let insertOrSwipeCard = NSLocalizedString(
            "Insert Or Swipe Card",
            comment: "Message from the in-person payment card reader prompting user to insert or swipe their card")
        static let multipleContactlessCards = NSLocalizedString(
            "Multiple Contactless Cards Detected",
            comment: "Message from the in-person payment card reader when payment could not be taken because " +
            "multiple cards were detected")
        static let removeCard = NSLocalizedString(
            "Remove Card",
            comment: "Message from the in-person payment card reader prompting user to remove their card")
        static let swipeCard = NSLocalizedString(
            "Swipe Card",
            comment: "Message from the in-person payment card reader prompting user to swipe their card")
        static let tryAnotherCard = NSLocalizedString(
            "Try Another Card",
            comment: "Message from the in-person payment card reader prompting user to retry a payment using a " +
            "different card")
        static let tryAnotherReadMethod = NSLocalizedString(
            "Try Another Read Method",
            comment: "Message from the in-person payment card reader prompting user to retry a payment using a " +
            "different method, e.g. swipe, tap, insert")
    }
}

#endif
