# In-app Feedback

This feature was created to gather feedback from our users. Currently, feedback is gathered by:

- Showing an actionable card in My Store (Stats) — [`InAppFeedbackCardViewController.swift`](../WooCommerce/Classes/ViewRelated/InAppFeedback/InAppFeedbackCardViewController.swift)
- Showing actionable buttons in the Products tab banner —  [`ProductsTopBannerFactory.swift`](../WooCommerce/Classes/ViewRelated/Products/ProductsTopBannerFactory.swift)

The logic for when these actionable buttons are shown is located in [`InAppFeedbackCardVisibilityUseCase.swift`](../Yosemite/Yosemite/Stores/AppSettings/InAppFeedbackCardVisibilityUseCase.swift)

## Feature Banners

The feature is designed so that when we have new banners (messages) like the Products banner, we just have to add a new option in [`FeedbackType`](../Storage/Storage/Model/FeedbackType.swift). This `FeedbackType` is used by `InAppFeedbackCardVisibilityUseCase` to determine whether to show the buttons or not.

## Survey CSS

The negative feedback on the My Store (Stats) card and the "Give Feedback" button in the feature banners launch a `WebView` showing a [Crowdsignal](https://crowdsignal.com) survey. See [`SurveyCoordinatingController.swift`](../WooCommerce/Classes/ViewRelated/Survey/SurveyCoordinatingController.swift).

Aside from the survey questions, the other configuration that we did is the CSS for the survey. This is configured in Crowdsignal. But there is a **backup file** located in [`Resources/Crowdsignal/woo-mobile-survey-style.css`](../Resources/Crowdsignal/woo-mobile-survey-style.css).