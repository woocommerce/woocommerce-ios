import SwiftUI

struct TopBannerSwifty: View {
    @State var viewModel: TopBannerSwiftyViewModel
    @State private var isExpanded: Bool = true
    @State private var onTopButtonTapped: (() -> Void)?

    init(viewModel: TopBannerSwiftyViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._isExpanded = State(initialValue: !viewModel.expandable)
    }

    var body: some View {
        VStack {
            VStack {
                HStack(alignment: .top, spacing: 20) {

                    // Top Left Icon
                    if let icon = viewModel.icon {
                        Image(uiImage: icon)
                            .frame(width: 24.0, height: 24.0)
                            .scaledToFit()
                            .foregroundColor(topLeftIconColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        //Title
                        if let title = viewModel.title {
                            Text(title)
                                .font(.headline)
                                .accentColor(Color(.text))
                        }
                        // Info Text
                        if let info = viewModel.infoText, (isExpanded || viewModel.title == nil) {
                            Text(info)
                                .font(.body)
                                .accentColor(Color(.text))
                        }
                    }


                    // Top Right Icon
                    if viewModel.expandable {
                    switch viewModel.topButton {
                    case .chevron:
                        let image = isExpanded ? UIImage.chevronUpImage: UIImage.chevronDownImage
                        Image(uiImage: image)
                            .frame(width: 24.0, height: 24.0)
                            .scaledToFit()
                            .foregroundColor(Color(.textSubtle))
                    case .dismiss:
                        let image = UIImage.gridicon(.cross, size: CGSize(width: 24, height: 24))
                        Image(uiImage: image)
                            .frame(width: 24.0, height: 24.0)
                            .scaledToFit()
                            .foregroundColor(Color(.textSubtle))
                    default:
                        EmptyView()
                    }
                    }
                }.padding(16)



            }.onTapGesture {
                guard viewModel.expandable else {
                    return
                }
                onTopButtonTapped?()
                isExpanded.toggle()
            }

            // Action Buttons
            if isExpanded && viewModel.actionButtons.isNotEmpty {
                HStack(spacing: 1) {
                    ForEach(viewModel.actionButtons, id: \.title) { actionButton in
                        Button(action: {
                            actionButton.action()
                        }, label: {
                            Spacer()
                            Text(actionButton.title)
                                .accentColor(Color(.accent))
                                .padding(4)
                                .frame(height: 44)
                            Spacer()
                        }).background(backgroundColor)
                        .frame(height: 44)
                        .fixedSize(horizontal: false, vertical: false)
                    }
                }.background(separatorColor)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor((separatorColor)), alignment: .top)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor((separatorColor)), alignment: .bottom)
            }
        }.background(backgroundColor)
    }

    //    backgroundColor = .clear
    //    contentEdgeInsets = Style.defaultEdgeInsets
    //    tintColor = .accent
    //    titleLabel?.applyBodyStyle()
    //    titleLabel?.textAlignment = .natural
    //    setTitleColor(.accent, for: .normal)
    //    setTitleColor(.accentDark, for: .highlighted)

    private var backgroundColor: Color {
        switch viewModel.type {
        case .normal:
            return Color(.systemColor(.secondarySystemGroupedBackground))
        case .warning:
            return Color(.warningBackground)
        }
    }

    private var topLeftIconColor: Color {
        switch viewModel.type {
        case .normal:
            return Color(.textSubtle)
        case .warning:
            return Color(.warning)
        }
    }

    private var separatorColor: Color {
        return Color(.systemColor(.separator))
    }
}

struct TopBannerSwifty_Previews: PreviewProvider {

    private static func makeExpandableWithActionButtons() -> some View {
        let title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let icon: UIImage = .megaphoneIcon
        let infoText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." +
            " Cras leo quam, auctor sit amet lectus nec, vehicula lobortis nunc."
        let giveFeedbackAction = TopBannerSwiftyViewModel.ActionButton(title: "Give Feedback") {
            print("Give Feedback button pressed")
        }
        let dismissAction = TopBannerSwiftyViewModel.ActionButton(title: "Dismiss") {
            print("Dismiss button pressed")
        }
        let actions = [giveFeedbackAction, dismissAction]
        let viewModel = TopBannerSwiftyViewModel(title: title,
                                                 infoText: infoText,
                                                 icon: icon,
                                                 expandable: true,
                                                 topButton: .chevron(handler: {

                                                 }),
                                                 actionButtons: actions,
                                                 type: .normal)
        return TopBannerSwifty(viewModel: viewModel)
    }

    private static func makeNotExpandableWithActionButtons() -> some View {
        let title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let icon: UIImage = .megaphoneIcon
        let infoText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." +
            " Cras leo quam, auctor sit amet lectus nec, vehicula lobortis nunc."
        let giveFeedbackAction = TopBannerSwiftyViewModel.ActionButton(title: "Give Feedback") {
            print("Give Feedback button pressed")
        }
        let dismissAction = TopBannerSwiftyViewModel.ActionButton(title: "Dismiss") {
            print("Dismiss button pressed")
        }
        let actions = [giveFeedbackAction, dismissAction]
        let viewModel = TopBannerSwiftyViewModel(title: title,
                                                 infoText: infoText,
                                                 icon: icon,
                                                 expandable: false,
                                                 topButton: .chevron(handler: {

                                                 }),
                                                 actionButtons: actions,
                                                 type: .warning)
        return TopBannerSwifty(viewModel: viewModel)
    }

    private static func makeTitleAndInfoTextWithoutIcon() -> some View {
        let icon: UIImage = .megaphoneIcon
        let title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let infoText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." +
            " Cras leo quam, auctor sit amet lectus nec, vehicula lobortis nunc."
        let viewModel = TopBannerSwiftyViewModel(title: title,
                                                 infoText: infoText,
                                                 icon: icon,
                                                 expandable: false,
                                                 topButton: .chevron(handler: {

                                                 }),
                                                 actionButtons: [],
                                                 type: .normal)
        return TopBannerSwifty(viewModel: viewModel)
    }

    private static func makeOnlyInfoText() -> some View {
        let icon: UIImage = .megaphoneIcon
        let infoText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." +
            " Cras leo quam, auctor sit amet lectus nec, vehicula lobortis nunc."
        let viewModel = TopBannerSwiftyViewModel(title: nil,
                                                 infoText: infoText,
                                                 icon: icon,
                                                 expandable: false,
                                                 topButton: .chevron(handler: {

                                                 }),
                                                 actionButtons: [],
                                                 type: .warning)
        return TopBannerSwifty(viewModel: viewModel)
    }

    static var previews: some View {
        makeExpandableWithActionButtons()
            .previewLayout(.fixed(width: 360, height: 100))
            .previewDisplayName("Expandable with Action Buttons")

        makeNotExpandableWithActionButtons()
            .previewLayout(.fixed(width: 360, height: 250))
            .previewDisplayName("Not Expandable with Action Buttons and Warning Type")

        makeTitleAndInfoTextWithoutIcon()
            .previewLayout(.fixed(width: 360, height: 170))
            .previewDisplayName("Title And Info Text without Icon")

        makeOnlyInfoText()
            .previewLayout(.fixed(width: 360, height: 150))
            .previewDisplayName("Only Info Text")
    }
}
