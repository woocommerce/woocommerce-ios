import SwiftUI

/// A multi-step modal view explaining POS benefits.
///
struct POSPromotionView: View {
    @StateObject private var viewModel: POSPromotionViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: POSPromotionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Paged content
                TabView(selection: $viewModel.selectedStep) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                        POSPromotionStepView(viewModel: viewModel.steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page indicator
                PageIndicatorView(
                    currentPage: viewModel.selectedStep,
                    totalPages: viewModel.totalSteps
                )
                .padding(.vertical, Layout.pageIndicatorVerticalPadding)

                // Primary CTA button
                Button(viewModel.primaryButtonTitle) {
                    withAnimation {
                        viewModel.primaryActionTapped()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.buttonHorizontalPadding)
                .padding(.bottom, Layout.buttonBottomPadding)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.closeButtonTapped()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        .onChange(of: viewModel.dismiss) {
            dismiss()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let pageIndicatorVerticalPadding: CGFloat = 16
    static let buttonHorizontalPadding: CGFloat = 16
    static let buttonBottomPadding: CGFloat = 16
}

// MARK: - Previews

#Preview {
    POSPromotionView(viewModel: POSPromotionViewModel())
}
