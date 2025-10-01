import SwiftUI
import WooFoundation

/// Text field style for search fields that includes a magnifier icon and clear button
struct POSSearchTextFieldStyle: TextFieldStyle {
    @Environment(\.posSearchTextFieldUnfocusedBorderColor) private var unfocusedBorderColor

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
            unfocusedBorderColor: unfocusedBorderColor,
            backgroundColor: .posSurfaceBright,
            cornerRadius: POSCornerRadiusStyle.medium.value,
            insets: EdgeInsets(top: POSPadding.small, leading: POSPadding.medium, bottom: POSPadding.small, trailing: POSPadding.medium),
            height: searchFieldHeight,
            content: { configuration in
                AnyView(
                    HStack(spacing: POSSpacing.small) {
                        Image(systemName: "magnifyingglass")
                            .accessibilityHidden(true)
                            .foregroundColor(.posOnSurface)
                            .font(.posBodyMediumBold)

                        configuration

                        if searchTerm.isNotEmpty {
                            Button {
                                searchTerm = ""
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .accessibilityLabel(Localization.searchFieldClearButtonAccessibilityLabel)
                                    .foregroundColor(.posOnSurfaceVariantHighest)
                                    .font(.posBodyMediumBold)
                            }
                        }
                    }
                )
            }
        ))
    }
}

private extension POSSearchTextFieldStyle {
    enum Localization {
        static let searchFieldClearButtonAccessibilityLabel = NSLocalizedString(
            "pos.searchview.searchField.clearButton.accessibilityLabel",
            value: "Clear Search",
            comment: "Accessibility label for the clear button in the Point of Sale search screen."
        )
    }
}
