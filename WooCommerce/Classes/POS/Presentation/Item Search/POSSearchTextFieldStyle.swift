import SwiftUI

/// Text field style for search fields that includes a magnifier icon and clear button
struct POSSearchTextFieldStyle: TextFieldStyle {
    private let focused: Bool
    @Binding private var searchTerm: String
    @ScaledMetric private var searchFieldHeight: CGFloat = 56.0

    init(focused: Bool, searchTerm: Binding<String>) {
        self.focused = focused
        self._searchTerm = searchTerm
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
        .textFieldStyle(WooRoundedBorderTextFieldStyle(
            focused: focused,
            focusedBorderColor: .posPrimary,
            unfocusedBorderColor: .posSurfaceBright,
            backgroundColor: .posSurfaceBright,
            height: searchFieldHeight,
            content: { configuration in
                AnyView(
                    HStack(spacing: POSSpacing.small) {
                        Image(systemName: "magnifyingglass")
                            .accessibilityHidden(true)
                            .foregroundColor(.posOnSurface)
                            .font(.posButtonSymbolMedium)
                            .padding(.leading, Defaults.horizontalPadding)

                        configuration

                        if searchTerm.isNotEmpty {
                            Button {
                                searchTerm = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .accessibilityLabel(Localization.searchFieldClearButtonAccessibilityLabel)
                                    .foregroundColor(.posOnSurfaceVariantHighest)
                                    .font(.posButtonSymbolMedium)
                            }
                            .padding(.trailing, Defaults.horizontalPadding)
                        }
                    }
                )
            }
        ))
    }
}

private extension POSSearchTextFieldStyle {
    enum Defaults {
        static let horizontalPadding: CGFloat = POSSpacing.medium
    }

    enum Localization {
        static let searchFieldClearButtonAccessibilityLabel = NSLocalizedString(
            "pos.searchview.searchField.clearButton.accessibilityLabel",
            value: "Clear Search",
            comment: "Accessibility label for the clear button in the Point of Sale search screen."
        )
    }
}
