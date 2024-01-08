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
        MultiSelectionList(title: "Languages",
                           allOptionsTitle: "All languages",
                           contents: viewModel.languages,
                           contentKeyPath: \.name, 
                           onQueryChanged: { query in
            // TODO: update content list
        }, 
                           onDismiss: onDismiss,
                           onCompletion: onCompletion)

    }
}

struct BlazeTargetLanguagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetLanguagePickerView(viewModel: BlazeTargetLanguagePickerViewModel(siteID: 123), onDismiss: {}, onCompletion: { _ in })
    }
}
