import SwiftUI

struct ProductCreationAIBarProgressStyle: ProgressViewStyle {

    var color: Color = .gray

    func makeBody(configuration: Configuration) -> some View {

        let progress = configuration.fractionCompleted ?? 0.0

        GeometryReader { geometry in

            VStack(alignment: .leading) {

                RoundedRectangle(cornerRadius: Layout.radius)
                    .fill(color.opacity(0.5))
                    .frame(height: Layout.height)
                    .frame(width: geometry.size.width)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Layout.radius)
                            .fill(color)
                            .frame(width: geometry.size.width * progress)
                            .animation(.linear, value: progress)
                    }
            }
        }
    }
}

private extension ProductCreationAIBarProgressStyle {
    enum Layout {
        static let height: CGFloat = 4
        static let radius: CGFloat = 8
    }
}

#Preview {
    ProgressView(value: 0.8)
        .progressViewStyle(ProductCreationAIBarProgressStyle())
}
