import SwiftUI

struct AdaptiveModalContainer<PrimaryView: View, SecondaryView: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @ViewBuilder let primaryView: (_ presentSecondaryView: (() -> Void)?) -> PrimaryView
    @ViewBuilder let secondaryView: (_ isPresented: Binding<Bool>) -> SecondaryView

    var body: some View {
        if horizontalSizeClass == .compact {
            ModalOnModalView(primaryView: primaryView, secondaryView: secondaryView)
        } else {
            SideBySideView(primaryView: primaryView, secondaryView: secondaryView)
        }
    }

    private struct ModalOnModalView: View {
        @ViewBuilder let primaryView: (_ presentSecondaryView: @escaping () -> Void) -> PrimaryView
        @ViewBuilder let secondaryView: (_ isPresented: Binding<Bool>) -> SecondaryView
        @State var isShowingSecondaryView = false
        @Environment(\.dismiss) var dismiss

        var body: some View {
            NavigationView {
                primaryView({
                    isShowingSecondaryView = true
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
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
        @Environment(\.dismiss) var dismiss
        @State var isShowingSecondaryView = true

        var body: some View {
            HStack {
                NavigationView {
                    secondaryView($isShowingSecondaryView)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
                .layoutPriority(1)

                NavigationView {
                    primaryView(nil)
                }
                .navigationViewStyle(.stack)
                .frame(minWidth: 400)
            }
        }
    }
}
