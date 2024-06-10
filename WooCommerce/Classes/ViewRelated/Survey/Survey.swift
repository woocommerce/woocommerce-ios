import SwiftUI

/// `SwiftUI` wrapper for `SurveyCoordinatingController`
///
struct Survey: UIViewControllerRepresentable {

    /// Source for the survey
    ///
    let source: SurveyViewController.Source

    /// Optional closure when survey is dismissed
    ///
    let onDismiss: (() -> Void)?

    init(source: SurveyViewController.Source,
         onDismiss: (() -> Void)? = nil) {
        self.source = source
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> SurveyCoordinatingController {
        return SurveyCoordinatingController(survey: source, onDismiss: onDismiss)

    }

    func updateUIViewController(_ uiViewController: SurveyCoordinatingController, context: Context) {
        // No-op
    }
}
