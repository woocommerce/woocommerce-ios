import SwiftUI

/// Handles the navigation actions in an optional profiler question view during store creation.
/// The question is skippable.
protocol OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() async
    func skipButtonTapped()
}

/// Shows an optional profiler question in the store creation flow.
/// The user can choose to skip the question or continue with an optional answer.
struct OptionalStoreCreationProfilerQuestionView<QuestionContent: View>: View {
    private let viewModel: StoreCreationProfilerQuestionViewModel & OptionalStoreCreationProfilerQuestionViewModel
    @ViewBuilder private let questionContent: () -> QuestionContent
    @State private var isWaitingForCompletion: Bool = false

    init(viewModel: StoreCreationProfilerQuestionViewModel & OptionalStoreCreationProfilerQuestionViewModel,
         @ViewBuilder questionContent: @escaping () -> QuestionContent) {
        self.viewModel = viewModel
        self.questionContent = questionContent
    }

    var body: some View {
        ScrollView {
            StoreCreationProfilerQuestionView<QuestionContent>(viewModel: viewModel, questionContent: questionContent)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.separator))
                Button(Localization.continueButtonTitle) {
                    Task { @MainActor in
                        isWaitingForCompletion = true
                        await viewModel.continueButtonTapped()
                        isWaitingForCompletion = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWaitingForCompletion))
                .padding(Layout.defaultPadding)
            }
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.skipButtonTitle) {
                    viewModel.skipButtonTapped()
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum Layout {
    static let dividerHeight: CGFloat = 1
    static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
}

private enum Localization {
    static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the button to continue with a profiler question.")
    static let skipButtonTitle = NSLocalizedString("Skip", comment: "Title of the button to skip a profiler question.")
}

#if DEBUG

private struct StoreCreationQuestionPreviewViewModel: StoreCreationProfilerQuestionViewModel, OptionalStoreCreationProfilerQuestionViewModel {
    let topHeader: String = "Store name"
    let title: String = "Which of these best describes you?"
    let subtitle: String = "Choose a category that defines your business the best."

    func continueButtonTapped() async {}
    func skipButtonTapped() {}
}

struct OptionalStoreCreationProfilerQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OptionalStoreCreationProfilerQuestionView(viewModel: StoreCreationQuestionPreviewViewModel()) {
                Text("question content")
            }
        }
    }
}

#endif
