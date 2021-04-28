import SwiftUI

/// `SwiftUI` wrapper for `SurveyCoordinatingController`
///
struct Survey: UIViewControllerRepresentable {

    /// Source for the survey
    ///
    let source: SurveyViewController.Source

    func makeUIViewController(context: Context) -> SurveyCoordinatingController {
        return SurveyCoordinatingController(survey: source)

    }

    func updateUIViewController(_ uiViewController: SurveyCoordinatingController, context: Context) {
        // No-op
    }
}
