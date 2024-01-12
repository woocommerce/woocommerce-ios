import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View to select multiple items from a list with an optional search bar.
struct MultiSelectionList<T: Hashable & Identifiable>: View {
    private let allOptionsTitle: String?
    private let contents: [T]
    /// Key path to find the content to be displayed
    private let contentKeyPath: KeyPath<T, String>
    private let onQueryChanged: ((String) -> Void)?

    @State private var query: String = ""
    @Binding private var selectedItems: Set<T>?

    /// Subtypes and static variables are not allowed on generic types
    /// so we have to use constants here.
    private let searchBarPlaceholderText = NSLocalizedString(
        "multipleSelectionList.search",
        value: "Search",
        comment: "Placeholder in the search bar of a multiple selection list"
    )

    init(allOptionsTitle: String? = nil,
         contents: [T],
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Binding<Set<T>?>,
         onQueryChanged: ((String) -> Void)? = nil) {
        self.allOptionsTitle = allOptionsTitle
        self.contents = contents
        self.contentKeyPath = contentKeyPath
        self.onQueryChanged = onQueryChanged
        self._selectedItems = selectedItems
    }

    var body: some View {
        VStack(spacing: 0) {
            if onQueryChanged != nil {
                SearchHeader(text: $query, placeholder: searchBarPlaceholderText)
            }

            List {
                if let allOptionsTitle {
                    Section {
                        HStack {
                            Text(allOptionsTitle)
                            Spacer()
                            Image(uiImage: .checkmarkStyledImage)
                                .renderedIf(allItemsSelected)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if allItemsSelected {
                                selectedItems = []
                            } else {
                                selectedItems = Set(contents)
                            }
                        }
                    }
                }

                Section {
                    ForEach(contents) { item in
                        HStack {
                            Text(item[keyPath: contentKeyPath])
                            Spacer()
                            Image(uiImage: .checkmarkStyledImage)
                                .renderedIf(isItemSelected(item))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleItem(item)
                        }
                    }
                }
            }
            .listStyle(.grouped)
        }
        .onChange(of: query) { value in
            onQueryChanged?(value)
        }
    }
}

// MARK: - Helper methods for selection
private extension MultiSelectionList {
    var allItemsSelected: Bool {
        guard let selectedItems else {
            return true
        }
        return selectedItems.count == contents.count
    }

    func isItemSelected(_ item: T) -> Bool {
        guard let selectedItems else {
            return true
        }
        return selectedItems.contains(item)
    }

    func toggleItem(_ item: T) {
        var updatedItems = selectedItems ?? []
        if updatedItems.contains(item) {
            updatedItems.remove(item)
        } else {
            updatedItems.insert(item)
        }
        selectedItems = updatedItems
    }
}

struct MultipleSelectionList_Previews: PreviewProvider {
    static var previews: some View {
        /// Using real structs for conformance to Hashable and Identifiable.
        let languages: [BlazeTargetLanguage] = [
            BlazeTargetLanguage(id: "1", name: "English", locale: "en"),
            BlazeTargetLanguage(id: "2", name: "Vietnamese", locale: "vi")
        ]
        MultiSelectionList(allOptionsTitle: "All languages",
                           contents: languages,
                           contentKeyPath: \.id,
                           selectedItems: .constant([]),
                           onQueryChanged: { _ in })
    }
}
