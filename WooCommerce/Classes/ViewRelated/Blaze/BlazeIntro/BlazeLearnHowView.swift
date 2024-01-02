import SwiftUI

/// View to display the learn how sheet of Blaze campaign creation
///
struct BlazeLearnHowView: View {
    @Binding var isPresented: Bool

    private let steps: [Step] = [.init(number: Localization.ChooseProduct.number,
                                       title: Localization.ChooseProduct.title,
                                       subtile: Localization.ChooseProduct.subtitle),
                                 .init(number: Localization.CustomizeTargeting.number,
                                       title: Localization.CustomizeTargeting.title,
                                       subtile: Localization.CustomizeTargeting.subtitle),
                                 .init(number: Localization.SetYourBudget.number,
                                       title: Localization.SetYourBudget.title,
                                       subtile: Localization.SetYourBudget.subtitle),
                                 .init(number: Localization.QuickReview.number,
                                       title: Localization.QuickReview.title,
                                       subtile: Localization.QuickReview.subtitle),
                                 .init(number: Localization.GoLive.number,
                                       title: Localization.GoLive.title,
                                       subtile: Localization.GoLive.subtitle)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBlock

            stepBlock
        }
    }
}

private extension BlazeLearnHowView {
    var titleBlock: some View {
        ZStack(alignment: .center) {
            HStack {
                Button(action: {
                    isPresented = false
                }, label: {
                    Image(uiImage: .closeButton)
                        .secondaryBodyStyle()
                })

                Spacer()
            }
            .padding(.horizontal, Layout.TitleBlock.closeButtonHorizontalPadding)

            HStack {
                Text(String(format: Localization.title, "Blaze"))
                    .fontWeight(.semibold)
                    .headlineStyle()
            }
        }
        .padding(.top, Layout.TitleBlock.topPadding)
    }

    var stepBlock: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(steps, id: \.title) { step in
                        StepView(step: step)

                        Divider()
                            .frame(height: Layout.StepBlock.dividerHeight)
                            .overlay(Color(uiColor: .systemBackground))
                    }
                }
                .background(Layout.StepBlock.backgroundColor)
            }
            .cornerRadius(Layout.StepBlock.cornerRadius)
        }
        .padding(Layout.contentPadding)
    }
}

private extension BlazeLearnHowView {
    struct Step {
        let number: String
        let title: String
        let subtile: String
    }

    struct StepView: View {
        let step: Step

        var title: AttributedString {
            var attributedText = AttributedString(.init(step.title + ":"))
            attributedText.font = UIFont.font(forStyle: .subheadline, weight: .semibold)
            attributedText.foregroundColor = .init(.text)
            return attributedText
        }

         var subtitle: AttributedString {
             var attributedText = AttributedString(.init(step.subtile))
             attributedText.font = UIFont.font(forStyle: .subheadline, weight: .regular)
             attributedText.foregroundColor = .init(.text)
             return attributedText
         }

        var body: some View {
            HStack(spacing: Layout.StepBlock.hSpacing) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: Layout.StepBlock.numberBackgroundSize, height: Layout.StepBlock.numberBackgroundSize)

                    Text(step.number)
                        .fontWeight(.semibold)
                        .captionStyle()
                }

                Text(title + " " + subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Layout.StepBlock.padding)
        }
    }
}

private extension BlazeLearnHowView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeLearnHowView.title",
            value: "Learn how %1$@ works",
            comment: "Title for the Blaze Learn How screen. %1$@ is replaced with string Blaze. Reads like: Learn how Blaze works"
        )
        enum ChooseProduct {
            static let number = NSLocalizedString(
                "blazeLearnHowView.chooseProduct.stepNumber",
                value: "1",
                comment: "Step number for Choose a product step"
            )
            static let title = NSLocalizedString(
                "blazeLearnHowView.chooseProduct.title",
                value: "Choose a product",
                comment: "Title for the Choose a product step"
            )
            static let subtitle = NSLocalizedString(
                "blazeLearnHowView.chooseProduct.subtitle",
                value: "Choose what to promote with Blaze.",
                comment: "Subtitle for the Choose a product step"
            )
        }
        enum CustomizeTargeting {
            static let number = NSLocalizedString(
                "blazeLearnHowView.customizeTargeting.stepNumber",
                value: "2",
                comment: "Step number for Customize Targeting step"
            )
            static let title = NSLocalizedString(
                "blazeLearnHowView.customizeTargeting.title",
                value: "Customize targeting",
                comment: "Title for Customize Targeting step"
            )
            static let subtitle = NSLocalizedString(
                "blazeLearnHowView.customizeTargeting.subtitle",
                value: "Select audience by location or interests, and see potential reach.",
                comment: "Subtitle for Customize Targeting step"
            )
        }
        enum SetYourBudget {
            static let number = NSLocalizedString(
                "blazeLearnHowView.setYourBudget.stepNumber",
                value: "3",
                comment: "Step number for Set Your Budget step"
            )
            static let title = NSLocalizedString(
                "blazeLearnHowView.setYourBudget.title",
                value: "Set your budget",
                comment: "Title for Set Your Budget step"
            )
            static let subtitle = NSLocalizedString(
                "blazeLearnHowView.setYourBudget.subtitle",
                value: "Decide on your spend and campaign length.",
                comment: "Subtitle for Set Your Budget step"
            )
        }
        enum QuickReview {
            static let number = NSLocalizedString(
                "blazeLearnHowView.quickReview.stepNumber",
                value: "4",
                comment: "Step number for Quick review step"
            )
            static let title = NSLocalizedString(
                "blazeLearnHowView.quickReview.title",
                value: "Quick review",
                comment: "Title for Quick review step"
            )
            static let subtitle = NSLocalizedString(
                "blazeLearnHowView.quickReview.subtitle",
                value: "Submit your ad for a fast moderator check.",
                comment: "Subtitle for Quick review step"
            )
        }
        enum GoLive {
            static let number = NSLocalizedString(
                "blazeLearnHowView.goLive.stepNumber",
                value: "5",
                comment: "Step number for Go live step"
            )
            static let title = NSLocalizedString(
                "blazeLearnHowView.goLive.title",
                value: "Go live",
                comment: "Title for Go live step"
            )
            static let subtitle = NSLocalizedString(
                "blazeLearnHowView.goLive.subtitle",
                value: "Watch as your promotion begins and track its success.",
                comment: "Subtitle for Go live step"
            )
        }
    }
}

private enum Layout {
    static let contentPadding: EdgeInsets = .init(top: 24, leading: 16, bottom: 24, trailing: 16)

    enum TitleBlock {
        static let closeButtonHorizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 24
    }

    enum StepBlock {
        static let dividerHeight: CGFloat = 1
        static let hSpacing: CGFloat = 12
        static let numberBackgroundSize: CGFloat = 24
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let backgroundColor = Color(uiColor: .init(light: UIColor.systemGray6,
                                                          dark: UIColor.systemGray5))
    }
}

struct BlazeLearnHowView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeLearnHowView(isPresented: .constant(true))
                          }
}
