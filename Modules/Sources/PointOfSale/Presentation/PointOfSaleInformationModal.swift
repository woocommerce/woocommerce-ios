import SwiftUI

// Container view for displaying information modals in the POS.
//
struct PointOfSaleInformationModal<Content: View>: View {
    @Environment(\.posMetrics) private var metrics
    @Binding var isPresented: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posModalParentSize) private var parentSize
    let title: AttributedString
    let content: Content

    // Used to make ScrollView height increase together with the content height.
    @State private var contentHeight: CGFloat = 0

    init(
        isPresented: Binding<Bool>,
        title: AttributedString,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if isCompactWidth {
            compactBody
        } else {
            regularBody
        }
    }

    private var regularBody: some View {
        VStack(spacing: metrics.spacing.xxLarge) {
            header

            ScrollView {
                modalContent
                    .measureHeight { height in
                        // Workaround for ScrollView not updating its height immediately on iOS 17
                        withAnimation(.easeIn(duration: 0)) {
                            contentHeight = height
                        }
                    }
            }
            .frame(maxHeight: contentHeight)

            okButton
        }
        .padding(contentPadding)
        .background(Color.posSurfaceBright)
        .frame(width: modalFrameWidth)
    }

    /// The phone bottom sheet adds the padding.
    private var compactBody: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.xLarge) {
            Text(title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            ViewThatFits(in: .vertical) {
                modalContent
                ScrollView {
                    modalContent
                }
            }

            okButton
        }
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        PointOfSaleModalHeader(isPresented: $isPresented, title: .constant(title))
    }

    private var modalContent: some View {
        VStack {
            content
        }
    }

    private var okButton: some View {
        Button(action: {
            isPresented = false
        }) {
            Text(Localization.okButtonTitle)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }
}

struct PointOfSaleInformationModalParagraphView<Content: View>: View {
    @Environment(\.posMetrics) private var metrics
    enum Style {
        case `default`
        case outlined
    }

    let content: Content
    let style: Style
    let spacing: KeyPath<POSMetrics.Scale, CGFloat>

    init(style: Style = .default, spacing: KeyPath<POSMetrics.Scale, CGFloat> = \.small, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.style = style
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: style == .default ? .leading : .center, spacing: metrics.spacing[keyPath: spacing]) {
            content
        }
        .if(style == .default, transform: { view in
            view.modifier(PointOfSaleInformationModalDefaultParagraphStyle())
        })
        .if(style == .outlined, transform: { view in
            view.modifier(PointOfSaleInformationModalOutlinedParagraphStyle())
        })
    }
}

private struct PointOfSaleInformationModalDefaultParagraphStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.posBodyLargeRegular())
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct PointOfSaleInformationModalOutlinedParagraphStyle: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.posBodySmallRegular())
            .foregroundStyle(Color.posOnSurface)
            .padding(metrics.padding.medium)
            .background(Color.posSurfaceDim)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension PointOfSaleInformationModal {
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var contentPadding: CGFloat {
        metrics.padding.xxLarge
    }

    var modalFrameWidth: CGFloat {
        min(Constants.modalFrameWidth, maxAvailableRegularWidth)
    }

    var maxAvailableRegularWidth: CGFloat {
        max(parentSize.width - (metrics.padding.medium * 2), 0)
    }

    enum Constants {
        static var modalFrameWidth: CGFloat { 896 }
    }
}

private enum Localization {
    static let okButtonTitle = NSLocalizedString(
        "pos.posInformationModal.ok.button.title",
        value: "OK",
        comment: "Title for the OK button on the pos information modal"
    )
}
