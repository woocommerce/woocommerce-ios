import SwiftUI

/// Hosting controller for `StoreCreationProfilerQuestionContainerView`
final class StoreCreationProfilerQuestionContainerHostingController: UIHostingController<StoreCreationProfilerQuestionContainerView> {
    init(viewModel: StoreCreationProfilerQuestionContainerViewModel) {
        super.init(rootView: StoreCreationProfilerQuestionContainerView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Container view for the profiler questions of the store creation flow.
struct StoreCreationProfilerQuestionContainerView: View {

    private let viewModel: StoreCreationProfilerQuestionContainerViewModel

    init(viewModel: StoreCreationProfilerQuestionContainerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        StoreCreationSellingStatusQuestionContainerView(storeName: "") { answer in
            // TODO
        } onSkip: {
            // TODO
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // TODO: on dismiss
            }
        }
    }
}

struct StoreCreationProfilerQuestionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationProfilerQuestionContainerView(viewModel: .init(storeName: "Test", onCompletion: { _ in }))
    }
}
