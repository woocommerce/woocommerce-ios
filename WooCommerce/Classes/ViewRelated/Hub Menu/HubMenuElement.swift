import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    let image: UIImage
    let text: String

    var body: some View {
        ZStack {
            Color(.listForeground)
            VStack {
                ZStack {
                    Color(.neutral(.shade0))
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                }
                .frame(width: Constants.imageSize, height: Constants.imageSize, alignment: .center)
                .cornerRadius(Constants.imageSize/2)
                .padding(.bottom, Constants.paddingBetweenElements)
                Text(text)
            }
        }
    }

    enum Constants {
        static let imageSize: CGFloat = 58
        static let iconSize: CGFloat = 34
        static let paddingBetweenElements: CGFloat = 8
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {

        HubMenuElement(image: .starOutlineImage(),
                       text: "Menu")
            .previewLayout(.fixed(width: 160, height: 160))
            .previewDisplayName("Hub Menu Element")
    }
}
