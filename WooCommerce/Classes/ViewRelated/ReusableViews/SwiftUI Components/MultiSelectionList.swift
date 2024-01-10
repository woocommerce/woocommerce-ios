import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View to select multiple items from a list with an optional search bar.
struct MultiSelectionList<T: Hashable & Identifiable>: View {
    private let title: String
    private let allOptionsTitle: String
    private let contents: [T]
    /// Key path to find the content to be displayed
    private let contentKeyPath: KeyPath<T, String>
    private let onQueryChanged: ((String) -> Void)?
    private let onDismiss: () -> Void
    private let onCompletion: (Set<T>?) -> Void

    @State private var query: String = ""
    @State private var selectedItems: Set<T>

    /// Subtypes and static variables are not allowed on generic types
    /// so we have to use constants here.
    private let searchBarPlaceholderText = NSLocalizedString(
        "multipleSelectionList.search",
        value: "Search",
        comment: "Placeholder in the search bar of a multiple selection list"
    )
    private let cancelButtonTitle = NSLocalizedString(
        "multipleSelectionList.cancel",
        value: "Cancel",
        comment: "Button to dismiss a multiple selection list"
    )
    private let saveButtonTitle = NSLocalizedString(
        "multipleSelectionList.save",
        value: "Save",
        comment: "Button to save the selections on a multiple selection list"
    )

    init(title: String,
         allOptionsTitle: String,
         contents: [T],
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Set<T>? = nil,
         onQueryChanged: ((String) -> Void)? = nil,
         onDismiss: @escaping () -> Void,
         onCompletion: @escaping (Set<T>?) -> Void) {
        self.title = title
        self.allOptionsTitle = allOptionsTitle
        self.contents = contents
        self.contentKeyPath = contentKeyPath
        self.onQueryChanged = onQueryChanged
        self.onDismiss = onDismiss
        self.onCompletion = onCompletion
        self.selectedItems = selectedItems ?? Set(contents)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if onQueryChanged != nil {
                    SearchHeader(text: $query, placeholder: searchBarPlaceholderText)
                }

                List {
                    Section {
                        HStack {
                            Text(allOptionsTitle)
                            Spacer()
                            Image(uiImage: .checkmarkStyledImage)
                                .renderedIf(selectedItems.count == contents.count)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedItems.isEmpty {
                                selectedItems = Set(contents)
                            } else {
                                selectedItems = []
                            }
                        }
                    }

                    Section {
                        ForEach(contents) { item in
                            HStack {
                                Text(item[keyPath: contentKeyPath])
                                Spacer()
                                Image(uiImage: .checkmarkStyledImage)
                                    .renderedIf(selectedItems.contains(item))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedItems.contains(item) {
                                    selectedItems.remove(item)
                                } else {
                                    selectedItems.insert(item)
                                }
                            }
                        }
                    }
                }
                .listStyle(.grouped)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButtonTitle, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        let allItemSelected = selectedItems.count == contents.count
                        onCompletion(allItemSelected ? nil : selectedItems)
                    }
                }
            }
            .onChange(of: query) { value in
                onQueryChanged?(value)
            }
        }
    }
}

struct MultipleSelectionList_Previews: PreviewProvider {
    static var previews: some View {
        /// Using real structs for conformance to Hashable and Identifiable.
        let languages: [BlazeTargetLanguage] = [
            BlazeTargetLanguage(id: "1", name: "English", locale: "en"),
            BlazeTargetLanguage(id: "2", name: "Vietnamese", locale: "vi")
        ]
        MultiSelectionList(title: "Languages",
                           allOptionsTitle: "All languages",
                           contents: languages,
                           contentKeyPath: \.id,
                           onQueryChanged: { _ in },
                           onDismiss: {},
                           onCompletion: { _ in })
    }
}
