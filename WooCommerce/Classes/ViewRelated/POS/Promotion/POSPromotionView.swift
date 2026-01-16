import SwiftUI

/// The content view for the POS Promotion modal, explaining POS benefits.
///
struct POSPromotionView: View {
    @ObservedObject var viewModel: POSPromotionViewModel
    @Binding var isPresented: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Whether to show the decorative image
    private var showImage: Bool {
        verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(spacing: Layout.spacing) {
            if showImage {
                Image(viewModel.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: Layout.imageHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            }

            VStack(spacing: Layout.spacing) {
                textPages

                PageIndicatorView(
                    currentPage: viewModel.selectedStep,
                    totalPages: viewModel.totalSteps
                )

                button
            }
            .padding(Layout.modalPadding)
        }
        .frame(minHeight: Layout.modalMinHeight)
        .overlay(alignment: .top) {
            closeButton
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

private extension POSPromotionView {
    @ViewBuilder var textPages: some View {
        TabView(selection: $viewModel.selectedStep) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                POSPromotionStepTextView(
                    title: viewModel.steps[index].title,
                    description: viewModel.steps[index].description
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    @ViewBuilder var button: some View {
        Group {
            if viewModel.isOnFinalStep {
                unstyledButton.buttonStyle(PrimaryButtonStyle())
            } else {
                unstyledButton.buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder var unstyledButton: some View {
        Button(viewModel.primaryButtonTitle) {
            viewModel.primaryActionTapped()
            if viewModel.dismiss {
                isPresented = false
            }
        }
    }

    @ViewBuilder var closeButton: some View {
        HStack {
            Spacer()
            Button {
                viewModel.closeButtonTapped()
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(Layout.closeButtonPadding)
            }
        }
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let closeButtonPadding: CGFloat = 16
    static let imageHeight: CGFloat = 210
    static let spacing: CGFloat = 16
    static let modalPadding: CGFloat = 16
    static let modalMinHeight: CGFloat = 534
}

// MARK: - UIKit Wrapper

/// Wrapper for presenting `POSPromotionView` as a floating modal from UIKit.
/// Uses `ModalOverlay` to display a centered modal with semi-transparent background.
///
struct POSPromotionModal_UIKit: View {
    @State var isPresented: Bool = true
    @StateObject private var viewModel: POSPromotionViewModel
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: POSPromotionViewModel())
    }

    var body: some View {
        ModalOverlay(isPresented: $isPresented, onDismiss: onDismiss) {
            POSPromotionView(viewModel: viewModel, isPresented: $isPresented)
        }
    }
}

// MARK: - Previews

#Preview {
    POSPromotionModal_UIKit()
}
