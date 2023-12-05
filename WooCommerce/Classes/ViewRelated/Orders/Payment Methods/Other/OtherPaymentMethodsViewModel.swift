import SwiftUI
import Combine

typealias OnMarkOrderAsCompleteCallback = ((_ noteText: String?) -> Void)

final class OtherPaymentMethodsViewModel: ObservableObject {
    @Published var noteText: String = Localization.noteTextPlaceholder
    let formattedTotal: String
    private let onMarkOrderAsComplete: OnMarkOrderAsCompleteCallback

    init(formattedTotal: String,
         onMarkOrderAsComplete: @escaping OnMarkOrderAsCompleteCallback) {
        self.formattedTotal = formattedTotal
        self.onMarkOrderAsComplete = onMarkOrderAsComplete
    }

    func onMarkOrderAsCompleteTapped() {
        let noteTextWasAdded = noteText.isNotEmpty && noteText != Localization.noteTextPlaceholder
        let noteText = noteTextWasAdded ? noteText : nil

        onMarkOrderAsComplete(noteText)
    }
}

private extension OtherPaymentMethodsViewModel {
    enum Localization {
        static let noteTextPlaceholder = NSLocalizedString("otherPaymentMethodsViewModel.note.placeholder",
                                                            value: "Enter optional note",
                                                            comment: "Placeholder for the text editor when adding a note in the payment methods view.")
    }
}
