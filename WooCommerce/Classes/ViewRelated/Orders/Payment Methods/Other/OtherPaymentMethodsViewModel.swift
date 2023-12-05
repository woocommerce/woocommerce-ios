import SwiftUI
import Combine

typealias OnMarkOrderAsCompleteCallback = ((_ noteText: String?) -> Void)

final class OtherPaymentMethodsViewModel: ObservableObject {
    @Published var noteText: String = Localization.noteTextPlaceholder
    let formattedTotal: String
    private let onMarkOrderAsComplete: OnMarkOrderAsCompleteCallback
    private let analytics: Analytics

    init(formattedTotal: String,
         analytics: Analytics = ServiceLocator.analytics,
         onMarkOrderAsComplete: @escaping OnMarkOrderAsCompleteCallback) {
        self.formattedTotal = formattedTotal
        self.analytics = analytics
        self.onMarkOrderAsComplete = onMarkOrderAsComplete
    }

    func onMarkOrderAsCompleteTapped() {
        let noteTextWasAdded = noteText.isNotEmpty && noteText != Localization.noteTextPlaceholder

        var addingNoteText: String?
        if noteTextWasAdded {
            addingNoteText = noteText
            analytics.track(.otherPaymentMethodsNoteAdded)
        }

        onMarkOrderAsComplete(addingNoteText)
    }
}

private extension OtherPaymentMethodsViewModel {
    enum Localization {
        static let noteTextPlaceholder = NSLocalizedString("otherPaymentMethodsViewModel.note.placeholder",
                                                            value: "Enter optional note",
                                                            comment: "Placeholder for the text editor when adding a note in the payment methods view.")
    }
}
