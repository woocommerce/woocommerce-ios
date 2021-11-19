import SwiftUI

struct JetpackInstallStepsView: View {
    // Closure invoked when Done button is tapped
    private let dismissAction: () -> Void

    private let siteURL: String

    @ScaledMetric private var scale: CGFloat = 1.0

    init(siteURL: String, dismissAction: @escaping () -> Void) {
        self.siteURL = siteURL
        self.dismissAction = dismissAction
    }

    var body: some View {
        VStack {
            // Header
            HStack(spacing: 8) {
                Image(uiImage: .jetpackGreenLogoImage)
                    .resizable()
                    .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                Image(uiImage: .connectionImage)
                    .resizable()
                    .frame(width: Constants.connectionIconSize * scale, height: Constants.connectionIconSize * scale)

                if let image = UIImage.wooLogoImage(tintColor: .white) {
                    Circle()
                        .foregroundColor(Color(.primary))
                        .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: Constants.wooIconSize.width * scale, height: Constants.wooIconSize.height * scale)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, Constants.contentHorizontalMargin)
            .padding(.top, Constants.contentTopMargin)

            Spacer()
        }
    }
}

private extension JetpackInstallStepsView {
    enum Constants {
        static let contentTopMargin: CGFloat = 69
        static let contentHorizontalMargin: CGFloat = 40
        static let logoSize: CGFloat = 40
        static let wooIconSize: CGSize = .init(width: 30, height: 18)
        static let connectionIconSize: CGFloat = 10
    }
}

struct JetpackInstallStepsView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallStepsView(siteURL: "automattic.com", dismissAction: {})
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
