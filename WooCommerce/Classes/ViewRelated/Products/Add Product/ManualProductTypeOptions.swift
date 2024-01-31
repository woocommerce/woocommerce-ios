import SwiftUI

/// View to show the manual product type creation options.
///
struct ManualProductTypeOptions: View {
    private let command: ProductTypeBottomSheetListSelectorCommand
    private let onOptionSelected: (BottomSheetProductType) -> Void

    init(command: ProductTypeBottomSheetListSelectorCommand,
         onOptionSelected: @escaping (BottomSheetProductType) -> Void) {
        self.command = command
        self.onOptionSelected = onOptionSelected
    }

    var body: some View {
        ForEach(command.data) { model in
            HStack(alignment: .top, spacing: Constants.margin) {
                Image(uiImage: model.actionSheetImage)
                    .font(.title3)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    Text(model.actionSheetTitle)
                        .bodyStyle()
                    Text(model.actionSheetDescription)
                        .subheadlineStyle()
                }
                Spacer()
            }
            .onTapGesture {
                onOptionSelected(model)
            }
        }
    }
}

private extension ManualProductTypeOptions {
    enum Constants {
        static let verticalSpacing: CGFloat = 4
        static let margin: CGFloat = 16
    }
}

#Preview {
    ManualProductTypeOptions(command: .init(selected: nil) { _ in }, onOptionSelected: { _ in })
}
