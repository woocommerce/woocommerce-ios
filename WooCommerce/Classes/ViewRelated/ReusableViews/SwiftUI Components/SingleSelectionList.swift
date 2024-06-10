import SwiftUI

/// View for selecting single item from a list
struct SingleSelectionList<T: Hashable>: View {
    /// Title of the screen
    private let title: String

    /// Items to be displayed
    private let items: [T]

    /// Key path to find the content to be displayed
    private let contentKeyPath: KeyPath<T, String>

    /// Callback for selection
    private let onSelection: ((T) -> Void)?

    @Binding private var selected: T

    @Environment(\.dismiss) private var dismiss

    /// Whether to show the Done button in the toolbar.
    ///
    /// The Done button should always be shown if it's needed to dismiss the view, e.g. when displaying the view in a sheet (in landscape mode).
    private let showDoneButton: Bool

    /// Background color for the view. `nil` uses system background color.
    private let backgroundColor: Color?

    init(title: String,
         items: [T],
         contentKeyPath: KeyPath<T, String>,
         selected: Binding<T>,
         showDoneButton: Bool = true,
         backgroundColor: Color? = Color(.listBackground),
         onSelection: ((T) -> Void)? = nil) {
        self.title = title
        self.items = items
        self.contentKeyPath = contentKeyPath
        self.onSelection = onSelection
        self._selected = selected
        self.showDoneButton = showDoneButton
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                SelectableItemRow(
                    title: item[keyPath: contentKeyPath],
                    selected: item == selected,
                    displayMode: .compact,
                    alignment: .trailing)
                .onTapGesture {
                    selected = item
                    onSelection?(item)
                }
            }
            .listRowInsets(.zero)
        }
        .listStyle(.plain)
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .if(showDoneButton, transform: { view in
            view.toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text(NSLocalizedString("Done", comment: "Done navigation button in selection list screens"))
                    })
                }
            })
        })
    }
}

struct SelectionList_Previews: PreviewProvider {
    static var previews: some View {
        SingleSelectionList(title: "Lunch",
                            items: ["🥪", "🥓", "🥗"],
                            contentKeyPath: \.self,
                            selected: .constant("🥓")) { _ in }

        SingleSelectionList(title: "Lunch",
                            items: ["🥪", "🥓", "🥗"],
                            contentKeyPath: \.self,
                            selected: .constant("🥓"),
                            showDoneButton: false,
                            backgroundColor: nil) { _ in }
    }
}
