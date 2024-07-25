import SwiftUI

struct PointOfSaleLoadingView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                progressView
                Spacer().frame(height: Layout.progressViewSpacing)
                Text(Localization.title)
                    .font(.posBody)
                Spacer().frame(height: Layout.textSpacing)
                Text(Localization.subtitle)
                    .font(.posTitle)
                    .bold()
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var progressView: some View {
        ProgressView()
            .progressViewStyle(IndefiniteCircularProgressViewStyle(
                size: Layout.progressViewSize,
                lineWidth: Layout.progressViewLineWidth,
                lineCap: .butt,
                circleColor: Color(.wooCommercePurple(.shade10)),
                fillColor: Color(.wooCommercePurple(.shade50))))
    }
}

private extension PointOfSaleLoadingView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.itemlistview.loading.title",
            value: "Starting up",
            comment: "Title of the Point of Sale entry point loading"
        )

        static let subtitle = NSLocalizedString(
            "pos.itemlistview.loading.subtitle",
            value: "Let’s serve some customers",
            comment: "Subtitle of the Point of Sale entry point loading"
        )
    }

    enum Layout {
        static let progressViewSize: CGFloat = 112
        static let progressViewLineWidth: CGFloat = 48
        static let textSpacing: CGFloat = 16
        static let progressViewSpacing: CGFloat = 72
    }
}

#Preview {
    PointOfSaleLoadingView()
}
