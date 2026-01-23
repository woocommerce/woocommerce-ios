import Foundation

struct LinkedProductsPromoCampaign {

    var configuration: FeatureAnnouncementCardViewModel.Configuration {
        .init(source: .productDetail,
              campaign: .linkedProductsPromo,
              title: Localization.cardTitle,
              message: Localization.cardMessage,
              buttonTitle: Localization.cardButtonTitle,
              image: .paymentsFeatureBannerImage,
              imageUrl: nil,
              imageDarkUrl: nil,
              showDismissConfirmation: false,
              dismissAlertTitle: "",
              dismissAlertMessage: "",
              showDividers: true,
              badgeType: .tip)
    }
}

extension LinkedProductsPromoCampaign {
    enum Localization {
        static let cardTitle = NSLocalizedString("Boost your sales with linked products", comment: "This text appears as the title of a promotional announcement card/banner displayed on the product detail screen to promote the linked products feature to store owners. The card is designed as a tip to encourage merchants to use upsells and cross-sells functionality.")

        static let cardMessage = NSLocalizedString(
            "Give your customers helpful and relevant product recommendations by adding upsells and cross-sells.",
            comment: "Message for the Linked Products announcement banner")

        static let cardButtonTitle = NSLocalizedString(
            "Try it now",
            comment: "Title for the button on the Linked Products announcement banner")
    }
}
