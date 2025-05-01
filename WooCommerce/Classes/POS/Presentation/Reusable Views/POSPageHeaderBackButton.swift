import SwiftUI

struct POSPageHeaderBackButton: View {
    private let configuration: POSPageHeaderBackButtonConfiguration

    init(configuration: POSPageHeaderBackButtonConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        Button(action: configuration.action) {
            Text(Image(systemName: Constants.backButtonIcon))
                .font(.posButtonSymbolLarge)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .foregroundColor(configuration.state == .disabled ? .posOnSurfaceVariantLowest : .posOnSurface)
                .padding(.horizontal, Constants.backButtonHorizontalPadding)
        }
        .disabled(configuration.state == .disabled || configuration.state == .shimmering)
        .if(configuration.state == .shimmering) { view in
            view.shimmering()
        }
    }
}

private extension POSPageHeaderBackButton {
    enum Constants {
        static let backButtonIcon = "chevron.backward"
        /// Icon container is 48x48, chevron icon width is 24px. Therefore, adding a horizontal padding (48-24)/2 = 12.
        static let backButtonHorizontalPadding: CGFloat = 12
    }
}
