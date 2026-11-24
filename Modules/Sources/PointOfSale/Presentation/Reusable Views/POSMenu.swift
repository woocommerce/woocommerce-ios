import SwiftUI

struct POSMenu<Content: View, Label: View>: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var isPresented = false
    @State private var pointer = POSMenuPointer()

    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            isPresented = true
        } label: {
            label()
                .frame(minWidth: POSHeaderLayoutConstants.compactBackButtonSize,
                       minHeight: POSHeaderLayoutConstants.compactBackButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            POSMenuPopover(isPresented: $isPresented, pointer: $pointer) {
                menuPanel
                    .environment(\.posLayoutScale, layoutScale)
                    .environment(\.colorScheme, colorScheme)
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .environment(\.layoutDirection, layoutDirection)
                    .environment(\.isEnabled, isEnabled)
                    .environment(\.posMenuPresentation, $isPresented)
            }
        }
        .onChange(of: isEnabled) {
            if !isEnabled {
                isPresented = false
            }
        }
    }

    private var menuPanel: some View {
        let shape = POSMenuBubble(pointer: pointer, arrowHeight: metrics.spacing.small, arrowBase: metrics.spacing.large)
        return ViewThatFits(in: .vertical) {
            menuContent
            ScrollView {
                menuContent
            }
        }
        .frame(idealWidth: Constants.preferredWidth, maxWidth: Constants.preferredWidth)
        .padding(.top, pointer.edge == .top ? metrics.spacing.small : metrics.spacing.none)
        .padding(.bottom, pointer.edge == .bottom ? metrics.spacing.small : metrics.spacing.none)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles(shape: shape)
        .padding(metrics.padding.xxLarge)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented = false
                }
        }
        .accessibilityAction(.escape) {
            isPresented = false
        }
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.none) {
            content()
        }
        .font(.posBodyMediumRegular())
        .labelStyle(POSMenuLabelStyle())
        .foregroundStyle(Color.posOnSurface)
        .padding(metrics.padding.small)
        .fixedSize(horizontal: false, vertical: true)
    }

    private enum Constants {
        static var preferredWidth: CGFloat {
            320
        }
    }
}

enum POSMenuAccessibility {
    static let moreActions = NSLocalizedString("pointOfSale.menu.moreActions.accessibilityLabel",
                                              value: "More actions",
                                              comment: "Accessibility label for the ellipsis button that opens a Point of Sale action menu.")
}

struct POSMenuPointer: Equatable {
    enum Edge {
        case top
        case bottom
    }

    var edge: Edge = .top
    var fraction: CGFloat = 0.5
}

private struct POSMenuBubble: Shape {
    let pointer: POSMenuPointer
    let arrowHeight: CGFloat
    let arrowBase: CGFloat

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > arrowHeight else { return Path() }
        let onTop = pointer.edge == .top
        let body = CGRect(x: rect.minX, y: rect.minY + (onTop ? arrowHeight : 0),
                          width: rect.width, height: rect.height - arrowHeight)
        let radius = min(POSCornerRadiusStyle.medium.value, min(body.width, body.height) / 2)
        let base = min(arrowBase, max(0, body.width - radius * 2))
        let center = min(max(rect.minX + pointer.fraction * rect.width, rect.minX + radius + base / 2), rect.maxX - radius - base / 2)
        let joinY = onTop ? body.minY : body.maxY
        var path = Path(roundedRect: body, cornerRadius: radius)
        path.move(to: CGPoint(x: center, y: onTop ? rect.minY : rect.maxY))
        path.addLine(to: CGPoint(x: center + base / 2, y: joinY))
        path.addLine(to: CGPoint(x: center - base / 2, y: joinY))
        path.closeSubpath()
        return path
    }
}

private struct POSMenuLabelStyle: LabelStyle {
    @Environment(\.posMetrics) private var metrics

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: metrics.spacing.medium) {
            configuration.icon
                .frame(minWidth: metrics.spacing.large)
            configuration.title
        }
    }
}

struct POSMenuButton<Label: View>: View {
    @Environment(\.posMenuPresentation) private var presentation
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.posMetrics) private var metrics
    @State private var didSelect = false
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var role: ButtonRole? = nil
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(role: role) {
            guard !didSelect else { return }
            guard let presentation else {
                action()
                return
            }
            didSelect = true
            var transaction = Transaction()
            transaction.disablesAnimations = true
            presentation.transaction(transaction).wrappedValue = false
        } label: {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(metrics.padding.medium)
                .frame(minHeight: metrics.menuRowMinHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(POSMenuButtonStyle(isHighlighted: isHovered || isFocused))
        .focused($isFocused)
        .onHover {
            isHovered = $0
        }
        .foregroundStyle(isEnabled ? (role == .destructive ? Color.posError : .posOnSurface) : .posOnDisabledContainer)
        .onDisappear {
            // The action can present another screen, so it runs after the menu has left the screen.
            guard didSelect else { return }
            didSelect = false
            action()
        }
    }
}

extension POSMenuButton where Label == Text {
    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.role = role
        self.action = action
        self.label = { Text(title) }
    }
}

private struct POSMenuButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    let isHighlighted: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isEnabled && (configuration.isPressed || isHighlighted) ? highlightColor : .clear)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
    }

    private var highlightColor: Color {
        colorScheme == .dark ? .posOutlineVariant : .posSurface
    }
}

extension EnvironmentValues {
    @Entry var posMenuPresentation: Binding<Bool>?
}

#if DEBUG
#Preview("POS overflow menu") {
    POSMenu {
        POSMenuButton("Orders", action: {})
        POSMenuButton("Settings", action: {})
        POSMenuButton("Unavailable action", action: {})
            .disabled(true)
        POSMenuButton("Delete", role: .destructive, action: {})
    } label: {
        Image(systemName: "ellipsis")
            .font(.posBodyLargeBold)
    }
    .accessibilityLabel(POSMenuAccessibility.moreActions)
    .posPadding(\.medium)
    .background(Color.posSurface)
}
#endif
