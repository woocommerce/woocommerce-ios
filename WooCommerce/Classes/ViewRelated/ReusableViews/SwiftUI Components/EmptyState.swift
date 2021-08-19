import SwiftUI

struct EmptyState: View {

    @State var title: String
    @State var description: String
    @State var image: UIImage?

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
            }
            Text(description)
                .multilineTextAlignment(.center)
                .bodyStyle()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: Constants.width, alignment: .center)
    }
}

private extension EmptyState {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let width: CGFloat = 168
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
