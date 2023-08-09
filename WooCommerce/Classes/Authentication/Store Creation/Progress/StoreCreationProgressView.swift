import SwiftUI

/// Hosting controller that wraps the `StoreCreationProgressView`.
final class StoreCreationProgressHostingViewController: UIHostingController<StoreCreationProgressView> {

    init(viewModel: StoreCreationProgressViewModel) {
        super.init(rootView: StoreCreationProgressView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct StoreCreationProgressView: View {
    @ObservedObject private var viewModel: StoreCreationProgressViewModel

    init(viewModel: StoreCreationProgressViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: Layout.contentSpacing) {
                    VStack(spacing: Layout.contentSpacing) {
                        Spacer()

                        title

                        progressView
                    }
                    // Make title and progress view occupy top half of the available space.
                    // This makes progress view appear at the center when we change the texts.
                    .frame(height: geometry.size.height / 2)

                    subtitle

                    Spacer()
                }
                .padding(.horizontal, Layout.horizantalPadding)
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

private extension StoreCreationProgressView {

    var title: some View {
        Text(viewModel.title)
            .multilineTextAlignment(.center)
            .secondaryTitleStyle()
    }

    var progressView: some View {
        ProgressView(value: viewModel.progressValue, total: viewModel.totalProgressAmount)
            .frame(height: Layout.ProgressView.height)
            .tint(.init(uiColor: .accent))
    }
    var subtitle: some View {
        // The subtitle is in an `.init` in order to support markdown.
        Text(.init(viewModel.subtitle))
            .bodyStyle()
    }

    enum Layout {
        static let contentSpacing: CGFloat = 24
        static let horizantalPadding: CGFloat = 40

        enum ProgressView {
            static let height: CGFloat = 8
        }
    }
}

struct StoreCreationProgressView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .buildingFoundations, estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .organizingStockRoom, estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .applyingFinishingTouches, estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .turningOnTheLights, estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .openingTheDoors, estimatedTimePerProgress: 1))
        StoreCreationProgressView(viewModel: StoreCreationProgressViewModel(initialProgress: .finished, estimatedTimePerProgress: 1))
    }
}
