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

    init(title: String,
         items: [T],
         contentKeyPath: KeyPath<T, String>,
         selected: Binding<T>,
         onSelection: ((T) -> Void)? = nil) {
        self.title = title
        self.items = items
        self.contentKeyPath = contentKeyPath
        self.onSelection = onSelection
        self._selected = selected
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: contentKeyPath) { item in
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
            .background(Color(.listBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text(NSLocalizedString("Done", comment: "Done navigation button in selection list screens"))
                    })
                }
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .wooNavigationBarStyle()
    }
}

struct SelectionList_Previews: PreviewProvider {
    static var previews: some View {
        SingleSelectionList(title: "Lunch",
                            items: ["🥪", "🥓", "🥗"],
                            contentKeyPath: \.self,
                            selected: .constant("🥓")) { _ in }
    }
}
