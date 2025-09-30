import Foundation

extension BookingDetailsViewModel {
    struct Section: Identifiable {
        var id: String {
            return content.id
        }

        let headerText: String?
        let footerText: String?
        let content: SectionContent

        init(
            headerText: String? = nil,
            footerText: String? = nil,
            content: SectionContent
        ) {
            self.headerText = headerText
            self.footerText = footerText
            self.content = content
        }
    }
}
