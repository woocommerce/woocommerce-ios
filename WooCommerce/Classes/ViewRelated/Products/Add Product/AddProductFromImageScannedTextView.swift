import SwiftUI

//struct AddProductFromImageScannedTextView: View {
//    @ObservedObject private var viewModel: AddProductFromImageViewModel.ScannedTextViewModel
//
//    init(viewModel: AddProductFromImageViewModel.ScannedTextViewModel) {
//        self.viewModel = viewModel
//    }
//
//    var body: some View {
//        HStack {
//            TextField("", text: $viewModel.text)
//                .font(.body)
//            Spacer()
//            Button(action: {
//                viewModel.isSelected.toggle()
//            }) {
//                Image(systemName: viewModel.isSelected ? "checkmark.circle.fill" : "circle")
//            }
//        }
//        .padding(.vertical, insets: .init(top: 8, leading: 0, bottom: 8, trailing: 0))
//    }
//}
//
//struct AddProductFromImageScannedTextView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddProductFromImageScannedTextView(viewModel: .init(text: "Parmesan", isSelected: true))
//    }
//}
