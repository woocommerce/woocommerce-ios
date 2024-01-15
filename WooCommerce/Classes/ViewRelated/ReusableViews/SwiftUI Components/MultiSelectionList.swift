import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View to select multiple items from a list with an optional search bar.
struct MultiSelectionList<T: Hashable & Identifiable>: View {
    private let headerMessage: String?
    private let allOptionsTitle: String?
    private let allOptionsFooter: String?
    private let itemsSectionHeader: String?
    private let contents: [T]
    /// Key path to find the content to be displayed
    private let contentKeyPath: KeyPath<T, String>
    private let onQueryChanged: ((String) -> Void)?

    /// Automatically checks All option if all items are selected.
    private let autoSelectAll: Bool

    @State private var query: String = ""
    @Binding private var selectedItems: Set<T>?

    /// Subtypes and static variables are not allowed on generic types
    /// so we have to use constants here.
    private let searchBarPlaceholderText = NSLocalizedString(
        "multipleSelectionList.search",
        value: "Search",
        comment: "Placeholder in the search bar of a multiple selection list"
    )

    private let searchResultHeader = NSLocalizedString(
        "multipleSelectionList.searchResults",
        value: "Search results",
        comment: "Header for the search result section on a a multiple selection list"
    )

    init(headerMessage: String? = nil,
         allOptionsTitle: String? = nil,
         allOptionsFooter: String? = nil,
         itemsSectionHeader: String? = nil,
         contents: [T],
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Binding<Set<T>?>,
         autoSelectAll: Bool = true,
         onQueryChanged: ((String) -> Void)? = nil) {
        self.headerMessage = headerMessage
        self.allOptionsTitle = allOptionsTitle
        self.allOptionsFooter = allOptionsFooter
        self.itemsSectionHeader = itemsSectionHeader
        self.contents = contents
        self.contentKeyPath = contentKeyPath
        self.onQueryChanged = onQueryChanged
        self.autoSelectAll = autoSelectAll
        self._selectedItems = selectedItems
    }

    var body: some View {
        VStack(spacing: 0) {
            if onQueryChanged != nil {
                SearchHeader(text: $query, placeholder: searchBarPlaceholderText)
            }

            List {
                Section {
                    if let allOptionsTitle, query.isEmpty {
                        HStack {
                            Text(allOptionsTitle)
                            Spacer()
                            Image(uiImage: .checkmarkStyledImage)
                                .renderedIf(allItemsSelected)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelectAll()
                        }
                    }
                } header: {
                    if let headerMessage, query.isEmpty {
                        Text(headerMessage)
                    }
                } footer: {
                    if let allOptionsFooter {
                        Text(allOptionsFooter)
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
                } header: {
                    if let itemsSectionHeader, contents.isNotEmpty {
                        Text(itemsSectionHeader)
                    } else if query.isNotEmpty {
                        Text(searchResultHeader)
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
        guard autoSelectAll else {
            return selectedItems == nil
        }

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

    func toggleSelectAll() {
        if allItemsSelected {
            selectedItems = []
        } else {
            selectedItems = nil
        }
    }

    func toggleItem(_ item: T) {
        var updatedItems = selectedItems ?? Set(contents)
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
