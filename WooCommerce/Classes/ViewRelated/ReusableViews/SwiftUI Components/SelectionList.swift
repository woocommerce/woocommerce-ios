import SwiftUI

struct SelectionList<T: Hashable>: View {
    /// Title of the screen
    private let title: String

    /// Items to be displayed
    private let items: [T]

    /// Key path to find the content to be displayed
    private let contentKeyPath: KeyPath<T, String>

    /// Callback for selection
    private let onSelection: ((T) -> Void)?

    @Binding private var selected: T
    @Environment(\.presentationMode) var presentation

    private let horizontalSpacing: CGFloat = 16

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
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(items, id: contentKeyPath) { item in
                            VStack(spacing: 0) {
                                SelectableItemRow(
                                    title: item[keyPath: contentKeyPath],
                                    selected: item == selected,
                                    displayMode: .compact,
                                    alignment: .trailing)
                                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                                    .onTapGesture {
                                        selected = item
                                        onSelection?(item)
                                    }
                                Divider()
                                    .padding(.leading, horizontalSpacing)
                                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                            }
                            .background(Color(.listForeground))
                        }
                    }
                }
                .background(Color(.listBackground))
                .ignoresSafeArea(.container, edges: .horizontal)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            presentation.wrappedValue.dismiss()
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
}

struct SelectionList_Previews: PreviewProvider {
    static var previews: some View {
        SelectionList(title: "Lunch",
                      items: ["🥪", "🥓", "🥗"],
                      contentKeyPath: \.self,
                      selected: .constant("🥓")) { _ in }
    }
}
