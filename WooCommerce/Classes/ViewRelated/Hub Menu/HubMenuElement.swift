import SwiftUI

enum HubMenuBadgeType {
    case newFeature
    case number(number: Int)

    var shouldBeRendered: Bool {
        switch self {
        case .newFeature:
            return true
        case let .number(number):
            return number > 0
        }
    }
}

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    private let image: UIImage
    private let imageColor: UIColor
    private let text: String
    private let badge: HubMenuBadgeType
    private let onTapGesture: (() -> Void)

    @Binding private var isDisabled: Bool

    init(image: UIImage, imageColor: UIColor, text: String, badge: HubMenuBadgeType, isDisabled: Binding<Bool>, onTapGesture: @escaping (() -> Void)) {
        self.image = image
        self.imageColor = imageColor
        self.text = text
        self.badge = badge
        self._isDisabled = isDisabled
        self.onTapGesture = onTapGesture
    }

    var body: some View {
        Button {
            guard !isDisabled else {
                return
            }
            isDisabled = true
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
                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                    }
                    .frame(width: Constants.imageSize, height: Constants.imageSize, alignment: .center)
                    .cornerRadius(Constants.imageSize/2)
                    .padding(.top, Constants.iconTopPadding)

                    Text(text)
                        .bodyStyle()
                        .padding(.top, Constants.paddingBetweenElements)
                        .padding(.bottom, Constants.minimumBottomPadding)
                    Spacer()
                }
                .frame(width: Constants.itemSize, height: Constants.itemSize)
                HubMenuBadge(type: badge)
                    .padding([.top, .trailing], 8)
                    .renderedIf(badge.shouldBeRendered)
            }
        }
        .disabled(isDisabled)
    }

    private struct HubMenuBadge: View {
        let type: HubMenuBadgeType

        var color: Color {
            switch type {
            case .newFeature:
                return Color(.accent)
            case .number(_):
                return .purple
            }
        }

        var body: some View {
            ZStack (alignment: .center) {
                Circle()
                    .fill(color)
                    .cornerRadius(Constants.cornerRadius)
                if case let .number(value) = type {
                    Text(String(value))
                        .foregroundColor(.white)
                        .bodyStyle()
                        .padding([.leading, .trailing], Constants.paddingBetweenElements)
                }

            }
            .frame(height: Constants.badgeSize)
            .fixedSize()
        }
    }

    private enum Constants {
        static let iconTopPadding: CGFloat = 32
        static let paddingBetweenElements: CGFloat = 8
        static let minimumBottomPadding: CGFloat = 2
        static let itemSize: CGFloat = 160
        static let badgeSize: CGFloat = 24
        static let cornerRadius: CGFloat = badgeSize/2
        static let imageSize: CGFloat = 58
        static let iconSize: CGFloat = 34
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {
        HubMenuElement(image: .starOutlineImage(),
                       imageColor: .brand,
                       text: "Menu",
                       badge: .number(number: 1),
                       isDisabled: .constant(false),
                       onTapGesture: {})
            .previewLayout(.fixed(width: 160, height: 160))
            .previewDisplayName("Hub Menu Element")
    }
}
