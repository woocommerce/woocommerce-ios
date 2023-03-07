import SwiftUI

/// Provides the copy for labels in the store creation profiler question view above the content.
protocol StoreCreationProfilerQuestionViewModel {
    var topHeader: String { get }
    var title: String { get }
    var subtitle: String { get }
}

/// Shows a profiler question in the store creation flow.
struct StoreCreationProfilerQuestionView<QuestionContent: View>: View {
    private let viewModel: StoreCreationProfilerQuestionViewModel
    private let questionContent: QuestionContent

    init(viewModel: StoreCreationProfilerQuestionViewModel,
         @ViewBuilder questionContent: () -> QuestionContent) {
        self.viewModel = viewModel
        self.questionContent = questionContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 16) {
                // Top header label.
                Text(viewModel.topHeader.uppercased())
                    .foregroundColor(Color(.secondaryLabel))
                    .footnoteStyle()

                // Title label.
                Text(viewModel.title)
                    .fontWeight(.bold)
                    .titleStyle()

                // Subtitle label.
                Text(viewModel.subtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
            }

            // Content of the profiler question.
            questionContent
        }
        .padding(Layout.contentPadding)
    }
}

private enum Layout {
    static let contentPadding: EdgeInsets = .init(top: 38, leading: 16, bottom: 16, trailing: 16)
}

#if DEBUG

private struct StoreCreationQuestionPreviewViewModel: StoreCreationProfilerQuestionViewModel {
    let topHeader: String = "Store name"
    let title: String = "Which of these best describes you?"
    let subtitle: String = "Choose a category that defines your business the best."
}

struct StoreCreationProfilerQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationProfilerQuestionView(viewModel: StoreCreationQuestionPreviewViewModel()) {
            Text("question content")
        }
    }
}

#endif
