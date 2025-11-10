import Foundation

extension BookingDetailsViewModel {
    struct Section: Identifiable {
        var id: String {
            return content.id
        }

        let header: Header?
        let footerText: String?
        let content: SectionContent

        init(
            header: Header? = nil,
            footerText: String? = nil,
            content: SectionContent
        ) {
            self.header = header
            self.footerText = footerText
            self.content = content
        }
    }
}

extension BookingDetailsViewModel.Section {
    enum Header {
        case empty
        case title(String)
    }
}
