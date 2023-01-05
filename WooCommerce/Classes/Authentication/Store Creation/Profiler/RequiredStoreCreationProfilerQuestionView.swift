import Combine
import SwiftUI

/// Handles the navigation action and provides the continue button state in a required profiler question view during store creation.
/// The question is not skippable.
protocol RequiredStoreCreationProfilerQuestionViewModel {
    /// Called when the continue button is tapped.
    func continueButtonTapped() async

    /// Called when the Help & Support button is tapped.
    func supportButtonTapped()

    /// Whether the continue button is enabled for the user to continue.
    var isContinueButtonEnabled: AnyPublisher<Bool, Never> { get }
}

/// Shows a mandatory profiler question during the store creation flow with a generic content.
struct RequiredStoreCreationProfilerQuestionView<QuestionContent: View>: View {
    private let viewModel: StoreCreationProfilerQuestionViewModel & RequiredStoreCreationProfilerQuestionViewModel
    @ViewBuilder private let questionContent: () -> QuestionContent
    @State private var isWaitingForCompletion: Bool = false
    @State private var isContinueButtonEnabled: Bool = false

    init(viewModel: StoreCreationProfilerQuestionViewModel & RequiredStoreCreationProfilerQuestionViewModel,
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
                .disabled(!isContinueButtonEnabled)
                .padding(Layout.defaultPadding)
            }
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SupportButton {
                    viewModel.supportButtonTapped()
                }
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.isContinueButtonEnabled) { isContinueButtonEnabled in
            self.isContinueButtonEnabled = isContinueButtonEnabled
        }
    }
}

private enum Layout {
    static let dividerHeight: CGFloat = 1
    static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
}

private enum Localization {
    static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the button to continue with a profiler question.")
}

#if DEBUG

private final class StoreCreationQuestionPreviewViewModel: StoreCreationProfilerQuestionViewModel, RequiredStoreCreationProfilerQuestionViewModel {
    let topHeader: String = "Store name"
    let title: String = "This question is required"
    let subtitle: String = "Choose an option to continue."
    @Published private var isContinueButtonEnabledValue: Bool = false

    var isContinueButtonEnabled: AnyPublisher<Bool, Never> {
        $isContinueButtonEnabledValue.eraseToAnyPublisher()
    }
    func continueButtonTapped() async {}
    func supportButtonTapped() {}
}

struct RequiredStoreCreationProfilerQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RequiredStoreCreationProfilerQuestionView(viewModel: StoreCreationQuestionPreviewViewModel()) {
                Text("question content")
            }
        }
    }
}

#endif
