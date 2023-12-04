import SwiftUI

struct PaymentsRow<Destination>: View where Destination: View {
    private let image: Image
    private let title: String
    private let subtitle: String?
    private let shouldBadgeImage: Bool
    private var isActive: Binding<Bool>?
    @ViewBuilder private let destination: (() -> Destination)?

    init(image: Image,
         title: String,
         subtitle: String? = nil,
         shouldBadgeImage: Bool = false,
         isActive: Binding<Bool>,
         @ViewBuilder destination: @escaping () -> Destination) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.shouldBadgeImage = shouldBadgeImage
        self.destination = destination
        self.isActive = isActive
    }

    var body: some View {
        HStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: PaymentsRowLayout.imageSize, maxHeight: PaymentsRowLayout.imageSize)
                .overlay(alignment: .topTrailing, content: {
                    Circle()
                        .fill(Color.withColorStudio(name: .wooCommercePurple, shade: .shade50))
                        .frame(width: PaymentsRowLayout.dotSize, height: PaymentsRowLayout.dotSize)
                        .renderedIf(shouldBadgeImage)
                })
                .accessibilityHidden(true)

            if let subtitle {
                VStack(alignment: .leading, spacing: PaymentsRowLayout.subtitleSpacing) {
                    Text(title)
                    Text(subtitle)
                        .footnoteStyle()
                }
            } else {
                Text(title)
            }

            Spacer()
        }
        .contentShape(Rectangle())

        navigationLink
    }

    @ViewBuilder
    private var navigationLink: some View {
        if let isActive,
           let destination {
            NavigationLink(isActive: isActive) {
                destination()
            } label: {
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}

extension PaymentsRow where Destination == Never {
    init(image: Image,
         title: String,
         subtitle: String? = nil,
         shouldBadgeImage: Bool = false) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.shouldBadgeImage = shouldBadgeImage
        self.destination = nil
        self.isActive = nil
    }
}

private enum PaymentsRowLayout {
    static let subtitleSpacing: CGFloat = 4.0
    static let imageSize: CGFloat = 24.0
    static let dotSize: CGFloat = 7.0
}

struct PaymentsRow_Previews: PreviewProvider {
    static var previews: some View {
        PaymentsRow(image: Image(uiImage: .creditCardIcon),
                    title: "Payments Row",
                    subtitle: "More details",
                    shouldBadgeImage: true)
        .previewLayout(.sizeThatFits)
    }
}
