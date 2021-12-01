import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    let image: UIImage
    let text: String

    var body: some View {
        VStack {
            ZStack {
                Color(.listBackground)
                Image(uiImage: image)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
            }
            .frame(width: Constants.imageSize, height: Constants.imageSize, alignment: .center)
            .cornerRadius(Constants.imageSize/2)
            .padding(.bottom, Constants.paddingBetweenElements)
            Text(text)
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

        HubMenuElement(image: UIImage(named: "icon-hub-menu")!,
                       text: "Menu")
            .previewLayout(.fixed(width: 166, height: 166))
            .previewDisplayName("Hub Menu Element")
    }
}
