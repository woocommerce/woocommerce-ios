import SwiftUI

struct POSPageHeaderBackButton: View {
    private let configuration: POSPageHeaderBackButtonConfiguration
    @Environment(\.posHeaderBackButtonIcon) private var environmentIcon
    @Environment(\.posHeaderBackButtonPadding) private var backButtonPadding

    init(configuration: POSPageHeaderBackButtonConfiguration) {
        self.configuration = configuration
    }

    private var buttonIcon: String {
        environmentIcon ?? configuration.buttonIcon ?? Constants.defaultBackButtonIcon
    }

    var body: some View {
        Button(action: configuration.action) {
            Text(Image(systemName: buttonIcon))
                .font(.posButtonSymbolLarge)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .foregroundColor(configuration.state == .disabled ? .posOnSurfaceVariantLowest : .posOnSurface)
                .padding(.horizontal, backButtonPadding)
        }
        .disabled(configuration.state == .disabled || configuration.state == .shimmering)
        .if(configuration.state == .shimmering) { view in
            view.shimmering()
        }
    }
}

private extension POSPageHeaderBackButton {
    enum Constants {
        static let defaultBackButtonIcon = "chevron.backward"
    }
}
