import SwiftUI

struct WooShippingHazmatCategoryList: View {
    private let categories: [ShippingLabelHazmatCategory] = {
        ShippingLabelHazmatCategory.allCases.filter {
            /// Filter out items that don't match the list on the web
            let exceptions: [ShippingLabelHazmatCategory] = [.none, .class4, .class5, .class6]
            return !exceptions.contains($0)
        }
    }()

    private let selectionHandler: (ShippingLabelHazmatCategory) -> Void

    @State private var selectedItem: ShippingLabelHazmatCategory?

    @Environment(\.dismiss) private var dismiss

    init(selectedItem: ShippingLabelHazmatCategory? = nil,
         selectionHandler: @escaping (ShippingLabelHazmatCategory) -> Void) {
        self.selectedItem = selectedItem
        self.selectionHandler = selectionHandler
    }

    var body: some View {
        NavigationStack {
            List(categories, id: \.self) { category in
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .opacity(selectedItem == category ? 1 : 0)

                    Text(category.localizedName)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.forward")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = category
                    selectionHandler(category)
                }
            }
            .listStyle(.plain)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension WooShippingHazmatCategoryList {
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingHazmatCategoryList.title",
            value: "Select Category",
            comment: "Title of the screen to select a category for hazardous materials in the shipping label creation flow"
        )
        static let cancel = NSLocalizedString(
            "wooShippingHazmatCategoryList.cancel",
            value: "Cancel",
            comment: "Button to dismiss the hazardous material category screen in the shipping label creation flow"
        )
    }
}

#Preview {
    WooShippingHazmatCategoryList(selectionHandler: { _ in })
}
