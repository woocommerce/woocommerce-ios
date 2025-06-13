import SwiftUI

struct PointOfSaleInformationModalViewModel {
    struct Paragraph: Hashable, Identifiable {
        enum Style {
            case `default`
            case outlined
        }

        let id = UUID()
        let lines: [AttributedString]
        let style: Style
        let identation: CGFloat

        init(_ lines: [AttributedString],
             style: Style = .default,
             identation: CGFloat = 0) {
            self.lines = lines
            self.style = style
            self.identation = identation
        }

        init(_ text: AttributedString,
             style: Style = .default,
             identation: CGFloat = 0) {
            self.lines = [text]
            self.style = style
            self.identation = identation
        }
    }
    let title: AttributedString
    let paragraphs: [Paragraph]
}

// SwiftUI modal for displaying information in the Point of Sale context
@available(iOS 17.0, *)
struct PointOfSaleInformationModal: View {
    @Binding var isPresented: Bool
    let viewModel: PointOfSaleInformationModalViewModel

    init(
        isPresented: Binding<Bool>,
        viewModel: PointOfSaleInformationModalViewModel
    ) {
        self._isPresented = isPresented
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            // Modal header with title and close button
            HStack {
                Text(viewModel.title)
                    .font(.posHeadingBold)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
            }
            .foregroundColor(Color.posOnSurface)

            // Display each paragraph (single or multiple lines)
            ForEach(viewModel.paragraphs, id: \.self) { paragraph in
                VStack {
                    ForEach(paragraph.lines, id: \.self) { text in
                        Text(text)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, paragraph.identation)
                .if(paragraph.style == .outlined) { view in
                    view
                        .frame(maxWidth: .infinity)
                        .padding(POSPadding.medium)
                        .background(Color(.posSurfaceDim))
                        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
                        .multilineTextAlignment(.center)
                }
                .if(paragraph.style == .default) { view in
                    view
                        .font(.posBodyLargeRegular())
                        .multilineTextAlignment(.leading)
                }
            }

            Button(action: {
                isPresented = false
            }) {
                Text(Localization.okButtonTitle)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(width: Constants.modalFrameWidth)
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleInformationModal {
    enum Constants {
        static let modalFrameWidth: CGFloat = 896
    }
}

private enum Localization {
    static let okButtonTitle = NSLocalizedString(
        "pos.posInformationModal.ok.button.title",
        value: "OK",
        comment: "Title for the OK button on the pos information modal"
    )
}
