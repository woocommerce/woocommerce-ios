import Yosemite

/// Keeps actionable reader guidance visible while the reader re-arms for another card presentation.
final class CardReaderEventPresentationFilter {
    private var isShowingMultipleContactlessCardsMessage = false

    func filter(_ event: CardReaderEvent) -> CardReaderEvent? {
        switch event {
        case .displayMessage(.multipleContactlessCardsDetected):
            isShowingMultipleContactlessCardsMessage = true
            return event
        case .waitingForInput where isShowingMultipleContactlessCardsMessage:
            return nil
        default:
            isShowingMultipleContactlessCardsMessage = false
            return event
        }
    }

    func reset() {
        isShowingMultipleContactlessCardsMessage = false
    }
}
