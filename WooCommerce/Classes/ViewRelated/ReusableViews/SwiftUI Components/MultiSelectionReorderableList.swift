import SwiftUI

/// View to select multiple items from a list and drag-and-drop to reorder them.
struct MultiSelectionReorderableList<T: Hashable, Content: View>: View {
    /// Ordered array of contents to be displayed in the list.
    @Binding private var contents: [T]

    /// Key path to find the content to be displayed.
    private let contentKeyPath: KeyPath<T, String>

    /// Items selected from the list of `contents`.
    @Binding private var selectedItems: Set<T>

    /// Items in addition to the list of `contents` that can't be moved or selected.
    private let disabledItems: [T]

    /// Accessory view to display next to disabled contents
    @ViewBuilder private let disabledAccessoryView: (T) -> Content

    init(contents: Binding<[T]>,
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Binding<Set<T>>,
         disabledItems: [T] = [],
         disabledAccessoryView: @escaping (T) -> Content) {
        self._contents = contents
        self.contentKeyPath = contentKeyPath
        self._selectedItems = selectedItems
        self.disabledItems = disabledItems
        self.disabledAccessoryView = disabledAccessoryView
    }

    init(contents: Binding<[T]>,
         contentKeyPath: KeyPath<T, String>,
         selectedItems: Binding<Set<T>>,
         disabledItems: [T] = []) where Content == EmptyView {
        self.init(contents: contents,
                  contentKeyPath: contentKeyPath,
                  selectedItems: selectedItems,
                  disabledItems: disabledItems,
                  disabledAccessoryView: { _ in EmptyView() })
    }

    var body: some View {
        List {
            Section {
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
            Section {
                ForEach(disabledItems, id: contentKeyPath) { item in
                    HStack(spacing: 0) {
                        Text(item[keyPath: contentKeyPath])
                        Spacer()
                        disabledAccessoryView(item)
                    }
                }
                .frame(height: Layout.disabledRowHeight)
                .listRowInsets(.init(top: 0, leading: Layout.disabledRowLeadingInset, bottom: 0, trailing: Layout.disabledRowTrailingInset))
            }
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

// MARK: - Constants
private enum Layout {
    static let disabledRowPadding: CGFloat = 10
    static let disabledRowHeight: CGFloat = 52
    static let disabledRowLeadingInset: CGFloat = 48
    static let disabledRowTrailingInset: CGFloat = 20
}

#Preview("List") {
    MultiSelectionReorderableList(contents: .constant(["🥪", "🥓", "🥗"]),
                                  contentKeyPath: \.self,
                                  selectedItems: .constant(["🥗", "🥓"]),
                                  disabledItems: ["🥫"],
                                  disabledAccessoryView: { item in
        Text("Learn more about \(item)")
    })
}

#Preview("Last selected item") {
    MultiSelectionReorderableList(contents: .constant(["🥪", "🥓", "🥗"]),
                                  contentKeyPath: \.self,
                                  selectedItems: .constant(["🥓"]))
}
