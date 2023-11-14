import SwiftUI

struct PaymentsRow: View {
    private let image: Image
    private let title: String
    private let subtitle: String?

    init(image: Image, title: String, subtitle: String? = nil) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: Layout.imageSize, maxHeight: Layout.imageSize)

            if let subtitle {
                VStack(alignment: .leading, spacing: Layout.subtitleSpacing) {
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
    }
}

private extension PaymentsRow {
    enum Layout {
        static let subtitleSpacing: CGFloat = 4.0
        static let imageSize: CGFloat = 24.0
    }
}

struct PaymentsRow_Previews: PreviewProvider {
    static var previews: some View {
        PaymentsRow(image: Image(uiImage: .creditCardIcon),
                    title: "Payments Row",
                    subtitle: "More details")
        .previewLayout(.sizeThatFits)
    }
}
