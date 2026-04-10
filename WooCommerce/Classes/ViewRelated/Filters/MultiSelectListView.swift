import SwiftUI

/// A SwiftUI view for selecting multiple items from a static list
/// Works with any type conforming to FilterType
struct MultiSelectListView: View {
    /// Title for the navigation bar
    let title: String

    /// All available options
    let options: [any FilterType]

    /// Currently selected items
    @State private var selectedItems: [any FilterType]

    /// Callback when selection changes
    private let onSelection: ([any FilterType]) -> Void

    init(title: String,
         options: [any FilterType],
         initialSelection: [any FilterType],
         onSelection: @escaping ([any FilterType]) -> Void) {
        self.title = title
        self.options = options
        self._selectedItems = State(initialValue: initialSelection)
        self.onSelection = onSelection
    }

    var body: some View {
        List {
            Button {
                selectedItems.removeAll()
                onSelection([])
            } label: {
                HStack {
                    Text(Localization.any)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "checkmark")
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .renderedIf(selectedItems.isEmpty)
                }
                .contentShape(Rectangle())
            }

            ForEach(options, id: \.description) { option in
                Button {
                    toggleSelection(for: option)
                } label: {
                    HStack {
                        Text(option.description)
                            .foregroundColor(.primary)

                        Spacer()

                        if isSelected(option) {
                            Image(systemName: "checkmark")
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.listBackground))
    }

    private func isSelected(_ option: any FilterType) -> Bool {
        selectedItems.contains { $0.description == option.description }
    }

    private func toggleSelection(for option: any FilterType) {
        if let index = selectedItems.firstIndex(where: { $0.description == option.description }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(option)
        }
        onSelection(selectedItems)
    }
}

private extension MultiSelectListView {
    enum Localization {
        static let any = NSLocalizedString(
            "multiSelectListView.any",
            value: "Any",
            comment: "Option to remove selections on multi selection list view"
        )
    }
}
