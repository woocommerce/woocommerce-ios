import SwiftUI

/// How a POS modal is shown on phone. Regular width always shows a centered card.
enum POSModalCompactStyle: Equatable {
    case dialog
    case bottomSheet
    case fullScreen(title: String)

    var fullScreenTitle: String? {
        guard case .fullScreen(let title) = self else {
            return nil
        }
        return title
    }
}

struct POSRootModalViewModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    @EnvironmentObject var modalManager: POSModalManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posHeaderTopPadding) private var topPadding
    @GestureState(resetTransaction: Transaction(animation: .interactiveSpring())) private var bottomSheetDragOffset: CGFloat = 0

    private let animationDuration = Constants.animationDuration
    private let scaleTransitionAmount = Constants.scaleTransitionAmount

    private var isFullScreen: Bool {
        (modalManager.isFullScreen || horizontalSizeClass == .compact) && !isCompactDialog && !isCompactBottomSheet
    }

    private var isCompactDialog: Bool {
        isCompactStyle(.dialog)
    }

    private var isCompactBottomSheet: Bool {
        isCompactStyle(.bottomSheet)
    }

    private func isCompactStyle(_ style: POSModalCompactStyle) -> Bool {
        activeCompactStyle == style
    }

    private var activeCompactStyle: POSModalCompactStyle? {
        horizontalSizeClass == .compact && !modalManager.isFullScreen ? modalManager.compactStyle : nil
    }

    private var dismissActionIfAllowed: (() -> Void)? {
        guard modalManager.allowsInteractiveDismissal else {
            return nil
        }
        return { modalManager.dismiss() }
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: modalManager.isPresented ? 8 : 0)
            .allowsHitTesting(!modalManager.isPresented)
            .accessibilityElement(children: modalManager.isPresented ? .ignore : .contain)
            .overlay {
                GeometryReader { geometry in
                    let modalPadding = isFullScreen ? metrics.padding.none : metrics.padding.medium
                    ZStack {
                        if modalManager.isPresented {
                            Color.posSurfaceDim.opacity(0.8)
                                .edgesIgnoringSafeArea(.all)
                                .onTapGesture {
                                    if modalManager.allowsInteractiveDismissal {
                                        modalManager.dismiss()
                                    }
                                }
                            // Don't scale/fade in the backdrop
                                .animation(nil, value: modalManager.isPresented)
                            // Phone full-screen: paint the bright surface as a sibling above the dim
                            // backdrop so the screen reads as a single solid take-over, with no
                            // backdrop showing through above the status bar.
                            if isFullScreen {
                                Color.posSurfaceBright
                                    .edgesIgnoringSafeArea(.all)
                                    .animation(nil, value: modalManager.isPresented)
                            }
                            if isCompactBottomSheet {
                                bottomSheet(parentSize: geometry.size, bottomSafeArea: geometry.safeAreaInsets.bottom)
                            } else {
                                ZStack {
                                    modalManager.getContent()
                                        .environment(\.posModalParentSize, geometry.size)
                                        .environment(\.posHeaderTopPadding, isFullScreen ? topPadding : nil)
                                        .environment(\.posModalDismissAction, { modalManager.dismiss() })
                                        .environment(\.posModalCompactStyle, activeCompactStyle)
                                        .posFullScreenFlowHeader(style: activeCompactStyle, dismissAction: dismissActionIfAllowed)
                                        .background(isFullScreen ? Color.clear : Color.posSurfaceBright)
                                        .cornerRadius(isFullScreen ? 0 : POSCornerRadiusStyle.extraLarge.value)
                                        .posShadow(isFullScreen ? .none : .large,
                                                   cornerRadius: isFullScreen ? 0 : POSCornerRadiusStyle.extraLarge.value)
                                        .padding(modalPadding)
                                }
                                .zIndex(1)
                                // Scale the modal container in and out, fading appropriately.
                                // Unfortunately combined doesn't work on removal.
                                // The extra ZStack prevents changing modalContent from scaling and fading, but the ZIndex needs to be
                                // consistent even when animating out, which it wouldn't be if unspecified.
                                .transition(.scale(scale: scaleTransitionAmount).combined(with: .opacity))
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                // Center cards across the bottom system inset; full-screen content and bottom sheets keep the safe area.
                .ignoresSafeArea(.container, edges: isFullScreen || isCompactBottomSheet ? [] : .bottom)
            }
            .animation(.easeInOut(duration: animationDuration), value: modalManager.isPresented)
            .posIgnoresHiddenKeyboardSafeArea()
    }
}

private extension POSRootModalViewModifier {
    func bottomSheet(parentSize: CGSize, bottomSafeArea: CGFloat) -> some View {
        VStack(spacing: metrics.spacing.none) {
            Spacer(minLength: metrics.spacing.xxLarge)

            modalManager.getContent()
                .environment(\.posModalParentSize, parentSize)
                .environment(\.posHeaderTopPadding, nil)
                .environment(\.posModalDismissAction, { modalManager.dismiss() })
                .environment(\.posModalCompactStyle, activeCompactStyle)
                .padding(metrics.bottomSheetContentInsets)
                // The home indicator area is already enough space under the content.
                .padding(.bottom, bottomSafeArea > 0 ? metrics.padding.none : metrics.padding.xxLarge)
                .frame(maxWidth: .infinity)
                // No close button, so VoiceOver closes the sheet with the escape gesture.
                .accessibilityElement(children: .contain)
                .accessibilityAction(.escape, dismissInteractively)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.posOnSurfaceVariantLowest)
                        .frame(width: Constants.grabberSize.width, height: Constants.grabberSize.height)
                        .padding(.top, metrics.padding.small)
                        .accessibilityElement()
                        .accessibilityLabel(Localization.grabberAccessibilityLabel)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { dismissInteractively() }
                        .accessibilityHidden(!modalManager.allowsInteractiveDismissal)
                }
            .background {
                UnevenRoundedRectangle(topLeadingRadius: POSCornerRadiusStyle.extraLarge.value,
                                       topTrailingRadius: POSCornerRadiusStyle.extraLarge.value)
                .fill(Color.posSurfaceBright)
                .ignoresSafeArea(edges: .bottom)
            }
            .offset(y: bottomSheetDragOffset)
            .gesture(bottomSheetDismissGesture)
        }
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }

    func dismissInteractively() {
        guard modalManager.allowsInteractiveDismissal else { return }
        modalManager.dismiss()
    }

    var bottomSheetDismissGesture: some Gesture {
        DragGesture()
            .updating($bottomSheetDragOffset) { value, offset, _ in
                guard modalManager.allowsInteractiveDismissal else { return }
                offset = max(0, value.translation.height)
            }
            .onEnded { value in
                guard modalManager.allowsInteractiveDismissal,
                      value.translation.height > Constants.bottomSheetDismissDistance else { return }
                modalManager.dismiss()
            }
    }

    enum Constants {
        static let animationDuration: CGFloat = 0.25
        static let scaleTransitionAmount: CGFloat = 0.9
        static let grabberSize = CGSize(width: 36, height: 5)
        static let bottomSheetDismissDistance: CGFloat = 80
    }

    enum Localization {
        static let grabberAccessibilityLabel = NSLocalizedString(
            "pos.modal.bottomSheet.grabber.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for the grabber at the top of a POS bottom sheet on phone. Activating it closes the sheet."
        )
    }
}

extension View {
    /// This should be applied at the root Point of Sale view only. It provides the styling for all POSModals. Nothing will show with this view alone.
    /// Ensure you've injected a `POSModalManager` environment object to the view you use this on.
    ///
    /// Trigger POS modal presentation using the `posModal` modifier
    ///
    /// - Returns: a view that displays modal content over the Point of Sale, when instructed to by child views using the `posModal` modifier
    func posRootModal() -> some View {
        self.modifier(POSRootModalViewModifier())
    }
}

struct POSModalViewModifier<Item: Identifiable & Equatable, ModalContent: View>: ViewModifier {
    let compactStyle: POSModalCompactStyle?
    @EnvironmentObject var modalManager: POSModalManager
    @EnvironmentObject var coverManager: POSFullScreenCoverManager
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let modalContent: (Item) -> ModalContent

    func body(content: Content) -> some View {
        content
            .onChange(of: item) { _, newItem in
                if let newItem {
                    // Don't show a modal if a full screen overlay is presented on top
                    guard !coverManager.isPresented else { return }

                    modalManager.present(compactStyle: compactStyle, onDismiss: {
                        // Internal dismissal, i.e. from tapping the background
                        onDismiss?()
                        item = nil
                    }) {
                        modalContent(newItem)
                            .animation(.default, value: item)
                    }
                } else {
                    // External dismissal
                    modalManager.dismiss()
                }
            }
    }
}

struct POSModalViewModifierForBool<ModalContent: View>: ViewModifier {
    let compactStyle: POSModalCompactStyle?
    @EnvironmentObject var modalManager: POSModalManager
    @EnvironmentObject var coverManager: POSFullScreenCoverManager
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Don't show a modal if a full screen overlay is presented on top
                    guard !coverManager.isPresented else { return }

                    modalManager.present(compactStyle: compactStyle, onDismiss: {
                        // Internal dismissal, i.e. from tapping the background
                        onDismiss?()
                        isPresented = false
                    }) {
                        modalContent()
                    }
                } else {
                    // External dismissal
                    modalManager.dismiss()
                }
            }
    }
}

extension View {
    /// Shows a modal view over the Point of Sale experience.
    ///
    /// Note that the content will not be redrawn in response to changes outside of the view builder.
    /// Use the `posModal(item: content:)` modifier to work around this limitation.
    /// The content is responsible for setting its own size – it will be presented at that size, with minimal padding around it.
    ///
    /// This will only work in a view heirarchy containing a `posRootModal` modifier.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the modal is shown.
    ///   - compactStyle: How the modal is shown on phone. `nil` keeps the full-screen take-over.
    ///   - content: Content to show – note this will not update in response to changes outside the scope of the view builder
    /// - Returns: a modified view which can show the modal content specified, when applicable.
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      compactStyle: POSModalCompactStyle? = nil,
                                      onDismiss: (() -> Void)? = nil,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifierForBool(compactStyle: compactStyle,
                                        isPresented: isPresented,
                                        onDismiss: onDismiss,
                                        modalContent: content))
    }

    /// Shows a modal view over the Point of Sale experience.
    ///
    /// The content will update when the item changes.
    /// The content is responsible for setting its own size – it will be presented at that size, with minimal padding around it.
    ///
    /// This will only work in a view heirarchy containing a `posRootModal` modifier.
    ///
    /// - Parameters:
    ///   - item: Binding to control when the modal is shown. When non-nil, the item is used to build the content.
    ///   - compactStyle: How the modal is shown on phone. `nil` keeps the full-screen take-over.
    ///   - content: Content to show
    /// - Returns: a modified view which can show the modal content specified, when applicable.
    func posModal<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        compactStyle: POSModalCompactStyle? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(compactStyle: compactStyle,
                                 item: item,
                                 onDismiss: onDismiss,
                                 modalContent: content))
    }
}

struct POSInteractiveDismissModifier: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager

    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: disabled) { _, newValue in
                modalManager.setInteractiveDismissal(!newValue)
            }
            .onAppear {
                modalManager.setInteractiveDismissal(!disabled)
            }
    }
}

extension View {
    /// Prevents a POS Modal from being dismissed by tapping on the background.
    func posInteractiveDismissDisabled(_ disabled: Bool = true) -> some View {
        self.modifier(POSInteractiveDismissModifier(disabled: disabled))
    }
}

struct POSModalFullScreenModifier: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager

    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: enabled) { _, newValue in
                modalManager.setFullScreen(newValue)
            }
            .onAppear {
                modalManager.setFullScreen(enabled)
            }
            .onDisappear {
                modalManager.setFullScreen(false)
            }
    }
}

extension View {
    func posModalFullScreen(_ enabled: Bool = true) -> some View {
        self.modifier(POSModalFullScreenModifier(enabled: enabled))
    }
}

// MARK: - POS Modal Parent Size Environment

/// Environment key for the space available to POS modals, measured by `POSRootModalViewModifier`
struct POSModalParentSizeKey: EnvironmentKey {
    /// `.zero` means not measured. `POSRootModalViewModifier` injects the measured size into every presented modal, and
    /// previews inject `POSPreviewHelpers.modalParentSize`.
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    /// The current screen size available to the POS modal
    var posModalParentSize: CGSize {
        get { self[POSModalParentSizeKey.self] }
        set { self[POSModalParentSizeKey.self] = newValue }
    }
}

// MARK: - POS Modal Compact Style Environment

private struct POSModalCompactStyleKey: EnvironmentKey {
    static let defaultValue: POSModalCompactStyle? = nil
}

extension EnvironmentValues {
    var posModalCompactStyle: POSModalCompactStyle? {
        get { self[POSModalCompactStyleKey.self] }
        set { self[POSModalCompactStyleKey.self] = newValue }
    }

    var isPOSModalFullScreenFlow: Bool {
        posModalCompactStyle?.fullScreenTitle != nil
    }
}

// MARK: - POS Modal Dismiss Action Environment

/// Environment key providing a direct dismiss action for POS modal content.
///
/// When modal content is inside a `NavigationStack` destination (e.g. the bookings refund flow),
/// parent view re-renders can disrupt `onChange(of:)` tracking on the pushed view, preventing
/// the binding-based dismiss path in `POSModalViewModifier` from firing.
/// This environment action provides a reliable alternative that calls `POSModalManager.dismiss()` directly.
struct POSModalDismissActionKey: EnvironmentKey {
    static var defaultValue: (() -> Void)? { nil }
}

extension EnvironmentValues {
    /// A closure that directly dismisses the current POS modal.
    var posModalDismissAction: (() -> Void)? {
        get { self[POSModalDismissActionKey.self] }
        set { self[POSModalDismissActionKey.self] = newValue }
    }
}

// MARK: - Previews for testing popular modals

#if DEBUG
#Preview("Card Present Alert") {
    @Previewable @StateObject var modalManager = POSModalManager()
    @Previewable @StateObject var coverManager = POSFullScreenCoverManager()
    @Previewable @State var showModal = false

    return VStack {
        Color.blue
            .ignoresSafeArea(.all)
        .onAppear {
            showModal = true
        }
    }
    .posModal(isPresented: $showModal) {
        PointOfSaleCardPresentPaymentAlert(alertType: .connectionSuccess(
            viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {
            })
        ))
    }
    .posRootModal()
    .environmentObject(modalManager)
    .environmentObject(coverManager)
}

#Preview("Barcode Scanner Setup") {
    @Previewable @StateObject var modalManager = POSModalManager()
    @Previewable @StateObject var coverManager = POSFullScreenCoverManager()
    @Previewable @State var showModal = false

    return VStack {
        Color.blue
            .ignoresSafeArea(.all)
        .onAppear {
            showModal = true
        }
    }
    .posModal(isPresented: $showModal) {
        POSBarcodeScannerSetup(isPresented: $showModal, analytics: EmptyPOSAnalytics())
    }
    .posRootModal()
    .environmentObject(modalManager)
    .environmentObject(coverManager)
}
#endif

extension POSMetrics {
    /// The top inset is measured from the top edge of the sheet, so the title clears the grabber.
    var bottomSheetContentInsets: EdgeInsets {
        EdgeInsets(top: padding.xxLarge + padding.large,
                   leading: padding.xxLarge,
                   bottom: padding.none,
                   trailing: padding.xxLarge)
    }
}
