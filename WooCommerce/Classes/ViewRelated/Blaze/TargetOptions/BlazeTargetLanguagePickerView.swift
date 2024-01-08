import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View for picking target languages for a Blaze campaign
struct BlazeTargetLanguagePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLanguagePickerViewModel

    private let onDismiss: () -> Void
    private let onCompletion: (Set<BlazeTargetLanguage>) -> Void

    init(viewModel: BlazeTargetLanguagePickerViewModel,
         onDismiss: @escaping () -> Void,
         onCompletion: @escaping (Set<BlazeTargetLanguage>) -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.onCompletion = onCompletion
    }

    var body: some View {
        MultiSelectionList(title: Localization.title,
                           allOptionsTitle: Localization.allTitle,
                           contents: viewModel.languages,
                           contentKeyPath: \.name, 
                           onQueryChanged: { query in
            // TODO: update content list
        },
                           onDismiss: onDismiss,
                           onCompletion: onCompletion)

    }
}

private extension BlazeTargetLanguagePickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetLanguagePickerView.title",
            value: "Languages",
            comment: "Title of the target language picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetLanguagePickerView.allTitle",
            value: "All languages",
            comment: "Title of the row to select all target languages for Blaze campaign creation"
        )
    }
}

struct BlazeTargetLanguagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetLanguagePickerView(viewModel: BlazeTargetLanguagePickerViewModel(siteID: 123), onDismiss: {}, onCompletion: { _ in })
    }
}
