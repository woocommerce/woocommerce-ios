import SwiftUI

struct WPComPushNotificationsBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
                stackedImages
                title
                detail
            }
            Spacer()
            footer
        }
        .padding([.leading, .bottom, .trailing], 16)
    }

    private var stackedImages: some View {
        Text(Localization.stackedImagesPlaceholder)
    }

    private var title: some View {
        Text(Localization.title)
            .font(.largeTitle)
            .fontWeight(.bold)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(Localization.description)
                .font(.body)
            Text(Localization.subdescription)
                .font(.body)
            Link(Localization.whatIsWPCom, destination: URL(string: "http://wordpress.com")!)
                .font(.body)
                .foregroundColor(Color(UIColor.accent))
        }
    }

    private var footer: some View {
        VStack {
            Button(Localization.continueButton) {

            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.notNowButton) {

            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

fileprivate extension WPComPushNotificationsBenefitsView {
    enum Localization {
        static let title = NSLocalizedString("wpcomPushNotificationsBenefitsView.title",
                                             value: "Unlock push notifications with WordPress.com",
                                             comment: "Title of the WordPress.com Push Notifications Benefits View")

        static let stackedImagesPlaceholder = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.stackedImagesPlaceholder",
            value: "stackedImages",
            comment: "Placeholder text for stacked images in the WordPress.com Push Notifications Benefits View"
        )

        static let description = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.description",
            value: "Connect your store to a WordPress.com account to get access to push notifications for new orders, reviews and more.",
            comment: "Main description text of the WordPress.com Push Notifications Benefits View"
        )

        static let subdescription = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.subdescription",
            value: "It only takes a minute.",
            comment: "Secondary description text of the WordPress.com Push Notifications Benefits View"
        )

        static let whatIsWPCom = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.whatIsWPCom",
            value: "What is WordPress.com?",
            comment: "Link text explaining what WordPress.com is in the Push Notifications Benefits View"
        )

        static let continueButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.continueButton",
            value: "Continue",
            comment: "Continue button title in the WordPress.com Push Notifications Benefits View"
        )

        static let notNowButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.notNowButton",
            value: "Not now",
            comment: "Not now button title in the WordPress.com Push Notifications Benefits View"
        )
    }
}

#Preview {
    WPComPushNotificationsBenefitsView()
}
