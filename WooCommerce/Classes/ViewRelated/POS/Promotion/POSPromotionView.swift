import SwiftUI

/// The content view for the POS Promotion modal, explaining POS benefits.
///
struct POSPromotionView: View {
    @Bindable var viewModel: POSPromotionViewModel
    @Binding var isPresented: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var scaledDescriptionPagesHeight: CGFloat = Layout.baseDescriptionPagesHeight
    @ScaledMetric(relativeTo: .body) private var scaledCompactDescriptionPagesHeight: CGFloat = Layout.baseCompactDescriptionPagesHeight

    /// Whether to show the decorative image
    private var showImage: Bool {
        verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    /// Height for the description pages, smaller in landscape due to wider text area
    private var descriptionPagesHeight: CGFloat {
        verticalSizeClass == .compact ? scaledCompactDescriptionPagesHeight : scaledDescriptionPagesHeight
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
                Text(viewModel.title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .if(!showImage) { title in
                        title.padding(Layout.titleNoImagePadding)
                    }

                descriptionPages

                PageIndicatorView(
                    currentPage: viewModel.selectedStep,
                    totalPages: viewModel.totalSteps
                )

                button
            }
            .padding(Layout.modalPadding)
        }
        .overlay(alignment: .top) {
            closeButton
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

private extension POSPromotionView {
    @ViewBuilder var descriptionPages: some View {
        TabView(selection: $viewModel.selectedStep) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                GeometryReader { geometry in
                    ScrollView {
                        Text(viewModel.stepDescriptions[index])
                            .font(.body)
                            .foregroundStyle(Color(.label))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: descriptionPagesHeight)
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
                    .foregroundStyle(Color(showImage ? .white : .label))
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
    static let modalPadding = EdgeInsets(top: .zero, leading: 16, bottom: 16, trailing: 16)
    static let titleNoImagePadding = EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 64)
    static let baseDescriptionPagesHeight: CGFloat = 96
    static let baseCompactDescriptionPagesHeight: CGFloat = 48
}

// MARK: - UIKit Wrapper

/// Wrapper for presenting `POSPromotionView` as a floating modal from UIKit.
/// Uses `ModalOverlay` to display a centered modal with semi-transparent background.
///
struct POSPromotionModal_UIKit: View {
    @State var isPresented: Bool = true
    @State private var viewModel: POSPromotionViewModel
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil,
         onShowWebView: @escaping (WebViewSheetViewModel) -> Void = { _ in }) {
        self.onDismiss = onDismiss
        self._viewModel = State(wrappedValue: POSPromotionViewModel(onShowWebView: onShowWebView))
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
