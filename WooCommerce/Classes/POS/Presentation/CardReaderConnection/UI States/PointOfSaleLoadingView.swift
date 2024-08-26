import SwiftUI

struct PointOfSaleLoadingView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                Spacer().frame(height: Layout.progressViewSpacing)
                Text(Localization.title)
                    .font(.posBodyRegular)
                Spacer().frame(height: Layout.textSpacing)
                Text(Localization.subtitle)
                    .font(.posTitleEmphasized)
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
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
        static let textSpacing: CGFloat = 16
        static let progressViewSpacing: CGFloat = 72
    }
}

#Preview {
    PointOfSaleLoadingView()
}
