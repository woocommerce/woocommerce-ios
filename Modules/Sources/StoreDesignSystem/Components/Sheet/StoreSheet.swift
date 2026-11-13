import SwiftUI

/// The panel of a bottom sheet: content on a surface-bright container, with the grabber strip above
/// and the design's minimum inset below. Present it with `storeSheet(isPresented:sizing:onDismiss:content:)`,
/// which also styles the system sheet (grabber, corners, background, detents). A `UIHostingController`
/// can host the panel, but must configure its `sheetPresentationController` itself.
public struct StoreSheet<Content: View>: View {
    private let content: Content

    @State private var bottomSafeAreaInset: CGFloat = 0

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            content
        }
        .padding(.top, StoreSheetLayout.grabberStripHeight)
        .padding(.bottom, StoreSheetLayout.bottomInset(safeAreaInset: bottomSafeAreaInset))
        .frame(maxWidth: .infinity)
        .background(Color.storeSurfaceBright)
        .onGeometryChange(for: CGFloat.self, of: { $0.safeAreaInsets.bottom }) { inset in
            bottomSafeAreaInset = inset
        }
    }
}

#Preview("Light") {
    SheetPreview()
}

#Preview("Dark") {
    SheetPreview()
        .preferredColorScheme(.dark)
}

private struct SheetPreview: View {
    @State private var isPresented = true

    var body: some View {
        Color.storeSectionBackground
            .ignoresSafeArea()
            .overlay {
                StoreButton("Show sheet") {
                    isPresented = true
                }
            }
            .storeSheet(isPresented: $isPresented) {
                VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                    Text("Date type")
                        .storeTextStyle(.titleLarge.strong)
                        .foregroundStyle(Color.storeOnSurface)
                    Text("Choose which orders to include in your performance metrics for the selected time range.")
                        .storeTextStyle(.bodyLarge)
                        .foregroundStyle(Color.storeOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p5)
            }
    }
}
