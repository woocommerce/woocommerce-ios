import SwiftUI

/// Hosting controller for `StoreCreationProfilerQuestionContainerView`
final class StoreCreationProfilerQuestionContainerHostingController: UIHostingController<StoreCreationProfilerQuestionContainerView> {
    init(viewModel: StoreCreationProfilerQuestionContainerViewModel, onSupport: @escaping () -> Void) {
        super.init(rootView: StoreCreationProfilerQuestionContainerView(viewModel: viewModel, onSupport: onSupport))
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

    @ObservedObject private var viewModel: StoreCreationProfilerQuestionContainerViewModel
    private let onSupport: () -> Void

    init(viewModel: StoreCreationProfilerQuestionContainerViewModel, onSupport: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSupport = onSupport
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProgressView(value: viewModel.currentQuestion.progress)
                .progressViewStyle(.linear)

            switch viewModel.currentQuestion {
            case .sellingStatus:
                StoreCreationSellingStatusQuestionContainerView(onContinue: { answer in
                    withAnimation {
                        viewModel.saveSellingStatus(answer)
                    }
                }, onSkip: {
                    withAnimation {
                        viewModel.saveSellingStatus(nil)
                    }
                })
            case .category:
                StoreCreationCategoryQuestionView(viewModel: .init(onContinue: { answer in
                    withAnimation {
                        viewModel.saveCategory(answer)
                    }
                }, onSkip: {
                    withAnimation {
                        viewModel.saveCategory(nil)
                    }
                }))
            case .country:
                StoreCreationCountryQuestionView(viewModel: .init(onContinue: { answer in
                    withAnimation {
                        viewModel.saveCountry(answer)
                    }
                }, onSupport: onSupport))
            case .challenges:
                StoreCreationChallengesQuestionView(viewModel: .init(onContinue: { answer in
                    withAnimation {
                        viewModel.saveChallenges(answer)
                    }
                }, onSkip: {
                    withAnimation {
                        viewModel.saveChallenges([])
                    }
                }))
            case .features:
                StoreCreationFeaturesQuestionView(viewModel: .init(onContinue: { answer in
                    withAnimation {
                        viewModel.saveFeatures(answer)
                    }
                }, onSkip: {
                    withAnimation {
                        viewModel.saveFeatures([])
                    }
                }))
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    withAnimation {
                        viewModel.backtrackOrDismissProfiler()
                    }
                }, label: {
                    if viewModel.currentQuestion.previousQuestion == nil {
                        Text(Localization.cancel)
                    } else {
                        Image(systemName: "chevron.backward")
                            .headlineLinkStyle()
                    }
                })
            }
        }
    }
}

private extension StoreCreationProfilerQuestionContainerView {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the store creation profiler flow")
    }
}

struct StoreCreationProfilerQuestionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationProfilerQuestionContainerView(viewModel: .init(storeName: "Test", onCompletion: { _ in }), onSupport: {})
    }
}
