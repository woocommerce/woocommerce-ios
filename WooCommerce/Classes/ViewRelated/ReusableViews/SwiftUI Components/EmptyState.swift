import SwiftUI

struct EmptyState: View {

    @State var title: String
    @State var description: String?
    @State var image: UIImage?
    @State var buttonTitle: String?
    @State var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Text(title)
                .multilineTextAlignment(.center)
                .headlineStyle()
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.width)
                    .accessibility(hidden: true)
            }
            if let description = description {
                Text(description)
                    .multilineTextAlignment(.center)
                    .bodyStyle()
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let buttonTitle {
                Button(buttonTitle) {
                    buttonAction?()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Constants.verticalSpacing)
                .frame(maxWidth: Constants.buttonWidth)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, Constants.horizontalSpacing)
    }
}

private extension EmptyState {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let horizontalSpacing: CGFloat = 24
        static let width: CGFloat = 168
        static let buttonWidth: CGFloat = 228
    }
}

struct EmptyState_Previews: PreviewProvider {
    static var previews: some View {
        EmptyState(title: "Something goes wrong",
                   description: "Please, double check your data or try using a different name in your request.",
                   image: .productErrorImage)
            .background(Color(UIColor.basicBackground))
            .environment(\.colorScheme, .light)


        EmptyState(title: "Something goes wrong",
                   description: "Please, double check your data or try using a different name in your request.",
                   image: .productErrorImage)
            .background(Color(UIColor.basicBackground))
            .environment(\.colorScheme, .dark)

    }
}
