import SwiftUI

/// View to select multiple items from a list and drag-and-drop to reorder them.
struct MultiSelectionReorderableList<T: Hashable>: View {
    /// Ordered array of contents to be displayed in the list.
    @Binding private var contents: [T]

    /// Key path to find the content to be displayed.
    private let contentKeyPath: KeyPath<T, String>

    /// Items selected from the list of `contents`.
    @Binding private var selectedItems: Set<T>

    init(contents: Binding<[T]>,
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Binding<Set<T>>) {
        self._contents = contents
        self.contentKeyPath = contentKeyPath
        self._selectedItems = selectedItems
    }

    var body: some View {
        List {
            ForEach(contents, id: contentKeyPath) { item in
                SelectableItemRow(title: item[keyPath: contentKeyPath],
                                  selected: isSelected(item),
                                  displayMode: .compact,
                                  selectionStyle: .checkcircle)
                    .listRowInsets(.zero)
                    .onTapGesture {
                        toggleItem(item)
                    }
                    .disabled(isLastSelected(item))
            }
            .onMove(perform: moveItem)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active)) // Always allow reordering
    }
}

// MARK: - Helper methods for selection and ordering
private extension MultiSelectionReorderableList {
    /// Moves an item within the list of contents.
    func moveItem(fromOffsets source: IndexSet, toOffset destination: Int) {
        contents.move(fromOffsets: source, toOffset: destination)
    }

    /// Checks if the given item is selected.
    func isSelected(_ item: T) -> Bool {
        selectedItems.contains(item)
    }

    /// Checks if the given item is the last selected item.
    /// This is used to disable that row, so it can't be deselected.
    func isLastSelected(_ item: T) -> Bool {
        isSelected(item) && selectedItems.count == 1
    }

    /// Selects or deselects the given item.
    func toggleItem(_ item: T) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
}

#Preview("List") {
    MultiSelectionReorderableList(contents: .constant(["🥪", "🥓", "🥗"]),
                                  contentKeyPath: \.self,
                                  selectedItems: .constant(["🥗", "🥓"]))
}

#Preview("Last selected item") {
    MultiSelectionReorderableList(contents: .constant(["🥪", "🥓", "🥗"]),
                                  contentKeyPath: \.self,
                                  selectedItems: .constant(["🥓"]))
}
