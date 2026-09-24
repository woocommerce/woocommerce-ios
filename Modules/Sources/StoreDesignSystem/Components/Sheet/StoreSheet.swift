import SwiftUI

/// The panel of a bottom sheet: a grabber strip above caller-provided content, on a surface-bright
/// container that keeps the design's minimum inset under the content. Present it with
/// `storeSheet(isPresented:sizing:onDismiss:content:)`, which adds the system presentation
/// (drag-to-dismiss, detents, dimming) styled to the design; a UIKit screen hosts it in a
/// `UIHostingController` and configures the sheet presentation controller itself.
///
/// - Note: The panel owns no state and no chrome beyond the grabber. The design asks every sheet to
///   support drag-to-dismiss and to include a close control, so content that is more than a quick
///   pick should start with a ``StoreTopAppBar`` whose navigation is `.close`. The grabber is
///   decorative (VoiceOver dismisses with the escape gesture) and, being the panel's own view, stays
///   draggable even when the content swallows the pan gesture, as a web view does.
public struct StoreSheet<Content: View>: View {
    private let content: Content

    /// The system inset under the panel, i.e. the home indicator area when the panel is the sheet's root.
    @State private var bottomSafeAreaInset: CGFloat = 0

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            grabber
            content
        }
        .padding(.bottom, StoreSheetLayout.bottomInset(safeAreaInset: bottomSafeAreaInset))
        .frame(maxWidth: .infinity)
        .background(Color.storeSurfaceBright)
        .onGeometryChange(for: CGFloat.self, of: { $0.safeAreaInsets.bottom }) { inset in
            bottomSafeAreaInset = inset
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.storeOnSurfaceVariantLowest)
            .frame(width: StoreSize.sheetGrabberWidth, height: StoreSize.sheetGrabberHeight)
            .frame(maxWidth: .infinity)
            .frame(height: StoreSize.sheetGrabberAreaHeight)
            .accessibilityHidden(true)
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
