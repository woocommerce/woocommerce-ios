import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    let image: UIImage
    let imageColor: UIColor
    let text: String
    let badge: Int
    let onTapGesture: (() -> Void)

    @ScaledMetric var imageSize: CGFloat = 58
    @ScaledMetric var iconSize: CGFloat = 34

    var body: some View {
        Button {
            onTapGesture()
        } label: {
            ZStack(alignment: .topTrailing) {

                VStack {
                    ZStack {
                        Color(UIColor(light: .listBackground,
                                      dark: .secondaryButtonBackground))
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(imageColor))
                            .frame(width: iconSize, height: iconSize)
                    }
                    .frame(width: imageSize, height: imageSize, alignment: .center)
                    .cornerRadius(imageSize/2)
                    .padding(.bottom, Constants.paddingBetweenElements)
                    Text(text)
                        .bodyStyle()
                }
                .frame(width: Constants.itemSize, height: Constants.itemSize)
                HubMenuBadge(value: badge)
                    .padding([.top, .trailing], 8)
                    .renderedIf(badge > 0)
            }
        }
    }

    private struct HubMenuBadge: View {
        let value: Int

        var body: some View {
            ZStack (alignment: .center) {
                Rectangle()
                    .fill(.purple)
                    .cornerRadius(Constants.cornerRadius)
                Text(String(value))
                    .foregroundColor(.white)
                    .bodyStyle()
                    .padding([.leading, .trailing], Constants.paddingBetweenElements)
            }
            .frame(height: Constants.badgeSize)
            .fixedSize()
        }
    }

    enum Constants {
        static let paddingBetweenElements: CGFloat = 8
        static let itemSize: CGFloat = 160
        static let badgeSize: CGFloat = 24
        static let cornerRadius: CGFloat = badgeSize/2
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {
        HubMenuElement(image: .starOutlineImage(),
                       imageColor: .blue,
                       text: "Menu",
                       badge: 1,
                       onTapGesture: {})
            .previewLayout(.fixed(width: 160, height: 160))
            .previewDisplayName("Hub Menu Element")
    }
}
