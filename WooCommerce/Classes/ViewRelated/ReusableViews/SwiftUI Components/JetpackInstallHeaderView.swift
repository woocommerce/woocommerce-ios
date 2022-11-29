import SwiftUI

/// Header view on top of the screens in Jetpack Install flows
///
struct JetpackInstallHeaderView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var isError: Bool = false

    var body: some View {
        HStack(spacing: Constants.headerContentSpacing) {
            Image(uiImage: .jetpackGreenLogoImage)
                .resizable()
                .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
            Image(uiImage: .connectionImage)
                .resizable()
                .flipsForRightToLeftLayoutDirection(true)
                .frame(width: Constants.connectionIconSize * scale, height: Constants.connectionIconSize * scale)

            if let image = UIImage.wooLogoImage(tintColor: .white), isError == false {
                Circle()
                    .foregroundColor(Color(.withColorStudio(.wooCommercePurple, shade: .shade60)))
                    .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: Constants.wooIconSize.width * scale, height: Constants.wooIconSize.height * scale)
                    )
            }

            Image(systemName: "exclamationmark.circle.fill")
                .resizable()
                .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                .foregroundColor(Color(uiColor: .error))
                .renderedIf(isError)

            Spacer()
        }
    }
}

private extension JetpackInstallHeaderView {
    enum Constants {
        static let logoSize: CGFloat = 40
        static let wooIconSize: CGSize = .init(width: 30, height: 18)
        static let connectionIconSize: CGFloat = 10
        static let headerContentSpacing: CGFloat = 8
    }
}

struct JetpackInstallHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallHeaderView()
        JetpackInstallHeaderView(isError: true)
    }
}
