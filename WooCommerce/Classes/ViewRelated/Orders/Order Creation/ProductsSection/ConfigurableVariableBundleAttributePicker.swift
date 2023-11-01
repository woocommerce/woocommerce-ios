import SwiftUI
import Yosemite

/// Allows the user to pick a variation attribute for a bundle item from the attribute's options.
struct ConfigurableVariableBundleAttributePicker: View {
    @ObservedObject private var viewModel: ConfigurableVariableBundleAttributePickerViewModel

    init(viewModel: ConfigurableVariableBundleAttributePickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Text(viewModel.name)
                .bold()

            Picker("", selection: $viewModel.selectedOption) {
                ForEach(viewModel.options, id: \.self) {
                    Text($0).tag($0)
                }
            }
        }
    }
}

struct ConfigurableVariableBundleAttributePicker_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurableVariableBundleAttributePicker(viewModel: .init(attribute: .init(siteID: 1,
                                                                                    attributeID: 1,
                                                                                    name: "Color",
                                                                                    position: 1,
                                                                                    visible: true,
                                                                                    variation: true,
                                                                                    options: ["Orange", "Indigo"]),
                                                                   selectedOption: "Indigo"))
    }
}
