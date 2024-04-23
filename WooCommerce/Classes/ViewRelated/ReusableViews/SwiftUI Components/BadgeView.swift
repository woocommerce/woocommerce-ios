import SwiftUI

struct BadgeView: View {
    enum BadgeType: Equatable {
        case new
        case tip
        case remoteImage(lightUrl: URL, darkUrl: URL?)
        case customText(text: String)

        var title: String? {
            switch self {
            case .new:
                return Localization.newTitle
            case .tip:
                return Localization.tipTitle
            case .customText(let text):
                return text
            case .remoteImage:
                return nil
            }
        }
    }

    /// Internal background shape of the badge
    enum BackgroundShape {
        case roundedRectangle(cornerRadius: CGFloat)
        case circle

        static var defaultShape: BackgroundShape {
            .roundedRectangle(cornerRadius: Layout.cornerRadius)
        }
    }

    /// UI customizations for the badge.
    struct Customizations {
        let textColor: Color
        let backgroundColor: Color

        init(textColor: Color = Color(.textBrand),
             backgroundColor: Color = Color(.wooCommercePurple(.shade0))) {
            self.textColor = textColor
            self.backgroundColor = backgroundColor
        }
    }

    private let type: BadgeType
    private let customizations: Customizations
    private let backgroundShape: BackgroundShape

    init(type: BadgeType) {
        self.type = type
        self.customizations = .init()
        self.backgroundShape = BackgroundShape.defaultShape
    }

    init(text: String,
         customizations: Customizations = .init(),
         backgroundShape: BackgroundShape = BackgroundShape.defaultShape) {
        self.type = .customText(text: text)
        self.customizations = customizations
        self.backgroundShape = backgroundShape
    }

    var body: some View {
        if let text = type.title {
            Text(text)
                .bold()
                .foregroundColor(customizations.textColor)
                .captionStyle()
                .padding(.leading, Layout.horizontalPadding)
                .padding(.trailing, Layout.horizontalPadding)
                .padding(.top, Layout.verticalPadding)
                .padding(.bottom, Layout.verticalPadding)
                .background(backgroundView())
        } else if case .remoteImage(let lightUrl, let darkUrl) = type {
            AdaptiveAsyncImage(anyAppearanceUrl: lightUrl, darkUrl: darkUrl, scale: 3) { imagePhase in
                switch imagePhase {
                case .success(let image):
                    image.scaledToFit()
                case .empty:
                    BadgeView(type: .new).redacted(reason: .placeholder)
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            EmptyView()
        }
    }
}

private extension BadgeView {
    @ViewBuilder
    func backgroundView() -> some View {
        switch backgroundShape {
        case .circle:
            if #available(iOS 17, *) {
                Circle()
                    .fill(customizations.backgroundColor)
                    .stroke(Color.white, lineWidth: Layout.borderLineWidth)
            } else {
                ZStack {
                    Circle()
                        .fill(customizations.backgroundColor)
                    Circle()
                        .stroke(Color.white, lineWidth: Layout.borderLineWidth)
                }
            }
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(customizations.backgroundColor)
        }
    }
}

private extension BadgeView.BadgeType {
    enum Localization {
        static let newTitle = NSLocalizedString("New", comment: "Title of the badge shown when advertising a new feature")
        static let tipTitle = NSLocalizedString("Tip", comment: "Title of the badge shown when promoting an existing feature")
    }
}

private extension BadgeView {
    enum Layout {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
    }
}

#if DEBUG
struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BadgeView(type: .new)
            BadgeView(type: .tip)
            BadgeView(text: "Custom text")
            BadgeView(text: "Customized colors", customizations: .init(textColor: .green, backgroundColor: .orange))
        }
    }
}
#endif
