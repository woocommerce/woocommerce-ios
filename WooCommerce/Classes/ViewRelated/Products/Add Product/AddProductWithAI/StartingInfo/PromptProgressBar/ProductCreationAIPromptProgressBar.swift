import SwiftUI

struct ProductCreationAIPromptProgressBar: View {
    @Binding var text: String
    @StateObject private var viewModel = ProductCreationAIPromptProgressBarViewModel()

    var body: some View {
        VStack(spacing: Layout.spacing, content: {
            ProgressView(value: viewModel.status.progress)
                .progressViewStyle(ProductCreationAIBarProgressStyle(color: viewModel.status.color))


            HStack(spacing: 0, content: {
                Text(viewModel.status.mainDescription + " ")
                    .font(.footnote)
                    .fontWeight(.semibold) +
                Text(viewModel.status.secondaryDescription)
                    .font(.footnote)
                    .fontWeight(.regular)

                Spacer()
            })
            .animation(.easeIn, value: viewModel.status)
        })
        .padding(Layout.padding)
        .background(Color(light: Color(.systemColor(.systemGray6)),
                          dark: Color(.systemColor(.systemGray5))))
        .cornerRadius(Layout.radius)
        .onAppear(perform: {
            viewModel.updateText(to: text)
        })
        .onChange(of: text, perform: { newText in
            viewModel.updateText(to: newText)
        })
    }

}

private extension ProductCreationAIPromptProgressBar {
    enum Layout {
        static let radius: CGFloat = 8
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
    }
}

#Preview {
    ProductCreationAIPromptProgressBar(text: .constant("example"))
        .frame(width: 200, height: 200)
}
