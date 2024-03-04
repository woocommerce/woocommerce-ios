import SwiftUI

/// `AdaptiveModalContainer` shows two views, primary and secondary
/// In horizontally regular environments, they are shown side-by-side, with the primary on the right (in an LTR system.)
/// In horizontally compact environments, the primary view is shown.
///
/// In compact environments, the primary view can use the `presentSecondaryView` closure to trigger modal presentation of the secondary view.
/// This closure is `nil` when the secondary view is shown side-by-side.
///
/// Each view is wrapped in its own Navigation Stack
///
/// Intended to be presented modally – a close button will be added to the leftmost navigation bar.
///
/// This was initially developed for the Order Form and Product Selector to be presented together on iPad.
struct AdaptiveModalContainer<PrimaryView: View, SecondaryView: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @ViewBuilder let primaryView: (_ presentSecondaryView: (() -> Void)?) -> PrimaryView
    @ViewBuilder let secondaryView: (_ isPresented: Binding<Bool>) -> SecondaryView
    var onViewContainerDismiss: (() -> Void)?

    var body: some View {
        if horizontalSizeClass == .compact {
            ModalOnModalView(primaryView: primaryView, secondaryView: secondaryView, onDimissButtonTapped: onViewContainerDismiss)
                .environment(\.adaptiveModalContainerPresentationStyle, .modalOnModal)
        } else {
            SideBySideView(primaryView: primaryView, secondaryView: secondaryView, onDimissButtonTapped: onViewContainerDismiss)
                .environment(\.adaptiveModalContainerPresentationStyle, .sideBySide)
        }
    }

    private struct ModalOnModalView: View {
        @ViewBuilder let primaryView: (_ presentSecondaryView: @escaping () -> Void) -> PrimaryView
        @ViewBuilder let secondaryView: (_ isPresented: Binding<Bool>) -> SecondaryView
        @State var isShowingSecondaryView = false
        var onDimissButtonTapped: (() -> Void)?

        var body: some View {
            NavigationView {
                primaryView({
                    isShowingSecondaryView = true
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            onDimissButtonTapped?()
                        }) {
                            Image(systemName: "xmark")
                        }
                    }
                }
                .sheet(isPresented: $isShowingSecondaryView) {
                    NavigationView {
                        secondaryView($isShowingSecondaryView)
                    }
                }
            }
            .navigationViewStyle(.stack)
        }
    }

    private struct SideBySideView: View {
        @ViewBuilder let primaryView: (_ presentSecondaryView: (() -> Void)?) -> PrimaryView
        @ViewBuilder let secondaryView: (_ isPresented: Binding<Bool>) -> SecondaryView
        var onDimissButtonTapped: (() -> Void)?
        @State var isShowingSecondaryView = true

        var body: some View {
            HStack(spacing: 0) {
                NavigationView {
                    secondaryView($isShowingSecondaryView)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    onDimissButtonTapped?()
                                }) {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .layoutPriority(1)

                Divider()

                NavigationView {
                    primaryView(nil)
                }
                .navigationViewStyle(.stack)
                .frame(minWidth: 400)
            }
        }
    }
}

enum AdaptiveModalContainerPresentationStyle {
    case modalOnModal
    case sideBySide
}

struct AdaptiveModalContainerPresentationStyleKey: EnvironmentKey {
    static let defaultValue: AdaptiveModalContainerPresentationStyle = .modalOnModal
}

extension EnvironmentValues {
    var adaptiveModalContainerPresentationStyle: AdaptiveModalContainerPresentationStyle {
        get { self[AdaptiveModalContainerPresentationStyleKey.self] }
        set { self[AdaptiveModalContainerPresentationStyleKey.self] = newValue }
    }
}
