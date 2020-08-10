import Foundation

/// Declares functions to create appropiate view controllers for the in-app Survey flow
///
protocol SurveyViewControllersFactoryProtocol {
    /// Creates a `ViewController` that conforms to `SurveyViewControllerOutputs` based on a given suvery source and a completion block
    ///
    func makeSurveyViewController(survey: SurveyViewController.Source, onCompletion: @escaping () -> Void) -> SurveyViewControllerOutputs

    /// Creates a `ViewController` that conforms to`SurveySubmittedViewControllerOutputs` by providing the necesary actions
    ///
    func makeSurveySubmittedViewController(onContactUsAction: @escaping () -> Void,
                                           onBackToStoreAction: @escaping () -> Void) -> SurveySubmittedViewControllerOutputs
}


/// Ceatess appropiate view controllers for the in-app Survey flow
///
final class SurveyViewControllersFactory: SurveyViewControllersFactoryProtocol {
    /// Returns a configured `SurveyViewController`
    ///
    func makeSurveyViewController(survey: SurveyViewController.Source, onCompletion: @escaping () -> Void) -> SurveyViewControllerOutputs {
        return SurveyViewController(survey: survey, onCompletion: onCompletion)
    }

    /// Returns a configured `SurveySubmittedViewController`
    ///
    func makeSurveySubmittedViewController(onContactUsAction: @escaping () -> Void,
                                           onBackToStoreAction: @escaping () -> Void) -> SurveySubmittedViewControllerOutputs {
        let completionViewController = SurveySubmittedViewController()
        completionViewController.onContactUsAction = onContactUsAction
        completionViewController.onBackToStoreAction = onBackToStoreAction
        return completionViewController
    }
}
