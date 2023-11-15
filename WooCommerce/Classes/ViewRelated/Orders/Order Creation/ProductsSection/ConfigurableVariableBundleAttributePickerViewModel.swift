import SwiftUI
import Yosemite

/// View model for `ConfigurableVariableBundleAttributePicker`.
final class ConfigurableVariableBundleAttributePickerViewModel: ObservableObject, Identifiable {
    /// Name of the variation attribute.
    var name: String {
        attribute.name
    }

    /// An array of options for the variation attribute.
    var options: [String] {
        attribute.options
    }

    /// Bound to the picker's selection.
    @Published var selectedOption: String

    /// Optionally selected variation attribute from the picker UI.
    var selectedAttribute: ProductVariationAttribute? {
        guard attribute.options.contains(selectedOption) else {
            return nil
        }
        return .init(id: attribute.attributeID, name: attribute.name, option: selectedOption)
    }

    /// Provides the view info about the attribute, like the name and options.
    private let attribute: ProductAttribute

    init(attribute: ProductAttribute, selectedOption: String?) {
        self.attribute = attribute
        self.selectedOption = selectedOption ?? ""
    }
}
