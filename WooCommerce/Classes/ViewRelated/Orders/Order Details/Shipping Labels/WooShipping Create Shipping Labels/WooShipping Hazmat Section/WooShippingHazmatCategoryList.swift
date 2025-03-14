import SwiftUI

struct WooShippingHazmatCategoryList: View {
    private let categories: [ShippingLabelHazmatCategory] = {
        ShippingLabelHazmatCategory.allCases.filter { $0 != .none }
    }()

    @Binding private var selectedItem: ShippingLabelHazmatCategory?

    @Environment(\.dismiss) private var dismiss

    init(selectedCategory: Binding<ShippingLabelHazmatCategory?>) {
        self._selectedItem = selectedCategory
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
    WooShippingHazmatCategoryList(selectedCategory: .constant(nil))
}
