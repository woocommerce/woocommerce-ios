import SwiftUI

struct POSRootModalViewModifier: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var modalParentSize: CGSize = UIScreen.main.bounds.size

    private let animationDuration = Constants.animationDuration
    private let scaleTransitionAmount = Constants.scaleTransitionAmount

    /// On phone we standardize the modal experience: every posModal renders as a full-screen
    /// take-over rather than a centered card, matching the rest of the phone-prototype UI.
    private var isFullScreen: Bool {
        modalManager.isFullScreen || horizontalSizeClass == .compact
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: modalManager.isPresented ? 8 : 0)
            .allowsHitTesting(!modalManager.isPresented)
            .accessibilityElement(children: modalManager.isPresented ? .ignore : .contain)
            .measureFrame { frame in
                updateModalParentSize(with: frame.size)
            }
            .overlay {
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
                    ZStack {
                        modalManager.getContent()
                            .environment(\.posModalParentSize, modalParentSize)
                            .environment(\.posModalDismissAction, { modalManager.dismiss() })
                            .background(Color.posSurfaceBright)
                            .cornerRadius(isFullScreen ? 0 : POSCornerRadiusStyle.extraLarge.value)
                            .posShadow(isFullScreen ? .none : .large,
                                       cornerRadius: isFullScreen ? 0 : POSCornerRadiusStyle.extraLarge.value)
                            .padding(isFullScreen ? POSPadding.none : POSPadding.medium)
                            // When full-screen we still respect the top safe area so the close
                            // button (and any header) doesn't sit flush against the status bar /
                            // notch. The bottom + horizontal edges still extend to the screen.
                            .ignoresSafeArea(.container, edges: isFullScreen ? [.horizontal, .bottom] : [])
                    }
                    .zIndex(1)
                    // Scale the modal container in and out, fading appropriately.
                    // Unfortunately combined doesn't work on removal.
                    // The extra ZStack prevents changing modalContent from scaling and fading, but the ZIndex needs to be
                    // consistent even when animating out, which it wouldn't be if unspecified.
                    .transition(.scale(scale: scaleTransitionAmount).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: animationDuration), value: modalManager.isPresented)
    }

    private func updateModalParentSize(with size: CGSize) {
        if size != modalParentSize && size != .zero {
            modalParentSize = size
        }
    }
}

private extension POSRootModalViewModifier {
    enum Constants {
        static let animationDuration: CGFloat = 0.25
        static let scaleTransitionAmount: CGFloat = 0.9
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

                    modalManager.present(onDismiss: {
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

                    modalManager.present(onDismiss: {
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
    ///   - content: Content to show – note this will not update in response to changes outside the scope of the view builder
    /// - Returns: a modified view which can show the modal content specifed, when applicable.
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      onDismiss: (() -> Void)? = nil,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifierForBool(isPresented: isPresented,
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
    ///   - content: Content to show
    /// - Returns: a modified view which can show the modal content specifed, when applicable.
    func posModal<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(item: item,
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

/// Environment key for tracking the current screen size in POS modals
struct POSModalParentSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = UIScreen.main.bounds.size
}

extension EnvironmentValues {
    /// The current screen size available to the POS modal
    var posModalParentSize: CGSize {
        get { self[POSModalParentSizeKey.self] }
        set { self[POSModalParentSizeKey.self] = newValue }
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
    static let defaultValue: (() -> Void)? = nil
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
