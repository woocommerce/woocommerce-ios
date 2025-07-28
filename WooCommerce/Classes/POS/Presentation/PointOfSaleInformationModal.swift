import SwiftUI

// Container view for displaying information modals in the POS.
//
struct PointOfSaleInformationModal<Content: View>: View {
    @Binding var isPresented: Bool
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

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            PointOfSaleModalHeader(isPresented: $isPresented, title: .constant(title))

            ScrollView {
                VStack {
                    content
                }
                .measureHeight { height in
                    // Workaround for ScrollView not updating its height immediately on iOS 17
                    withAnimation(.easeIn(duration: 0)) {
                        contentHeight = height
                    }
                }
            }
            .frame(maxHeight: contentHeight)

            Button(action: {
                isPresented = false
            }) {
                Text(Localization.okButtonTitle)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(width: Constants.modalFrameWidth)
    }
}

struct PointOfSaleInformationModalParagraphView<Content: View>: View {
    enum Style {
        case `default`
        case outlined
    }

    let content: Content
    let style: Style
    let spacing: CGFloat

    init(style: Style = .default, spacing: CGFloat = POSSpacing.small, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.style = style
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: style == .default ? .leading : .center, spacing: spacing) {
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
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.posBodySmallRegular())
            .foregroundStyle(Color.posOnSurface)
            .padding(POSPadding.medium)
            .background(Color.posSurfaceDim)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension PointOfSaleInformationModal {
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
