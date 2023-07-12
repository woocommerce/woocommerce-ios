import SwiftUI

/// Selectable and editable scanned text for generating product details in the "add product from image" flow in `AddProductFromImageView`.
struct AddProductFromImageScannedTextView: View {
    @ObservedObject private var viewModel: AddProductFromImageViewModel.ScannedTextViewModel

    init(viewModel: AddProductFromImageViewModel.ScannedTextViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            TextField("", text: $viewModel.text)
                .font(.body)
            Spacer()
            Button(action: {
                viewModel.isSelected.toggle()
            }) {
                Image(systemName: viewModel.isSelected ? "checkmark.circle.fill" : "circle")
            }
        }
        .padding(.vertical, insets: Layout.verticalPadding)
    }
}

private extension AddProductFromImageScannedTextView {
    enum Layout {
        static let verticalPadding: EdgeInsets = .init(top: 6, leading: 0, bottom: 6, trailing: 0)
    }
}

struct AddProductFromImageScannedTextView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AddProductFromImageScannedTextView(viewModel: .init(text: "Parmesan", isSelected: true))
            AddProductFromImageScannedTextView(viewModel: .init(text: "Looking for a healthy snack option that's both delicious and convenient?",
                                                                isSelected: false))
        }
    }
}
