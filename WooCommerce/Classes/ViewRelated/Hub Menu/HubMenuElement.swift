import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    let image: UIImage
    let text: String
    let onTapGesture: (() -> Void)

    @ScaledMetric var imageSize: CGFloat = 58
    @ScaledMetric var iconSize: CGFloat = 34

    var body: some View {
        Button {
            onTapGesture()
        } label: {
            VStack {
                ZStack {
                    Color(UIColor(light: .listBackground,
                                  dark: .secondaryButtonBackground))
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                }
                .frame(width: imageSize, height: imageSize, alignment: .center)
                .cornerRadius(imageSize/2)
                .padding(.bottom, Constants.paddingBetweenElements)
                Text(text)
                    .bodyStyle()
            }
        }
    }

    enum Constants {
        static let paddingBetweenElements: CGFloat = 8
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {
        HubMenuElement(image: .starOutlineImage(),
                       text: "Menu", onTapGesture: { })
            .previewLayout(.fixed(width: 160, height: 160))
            .previewDisplayName("Hub Menu Element")
    }
}
