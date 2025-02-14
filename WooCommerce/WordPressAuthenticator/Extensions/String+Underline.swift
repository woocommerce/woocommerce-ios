extension String {
    /// Creates an attributed string from one link section that's surrounded by underscores
    ///
    /// - Parameters:
    ///   - color: foreground color to use for the string (optional)
    ///   - linkColor: foreground color to use for the link (optional)
    /// - Returns: Attributed string
    /// - Note: "this _is_ an example" would color the "is" using the linkColor
    func withColor(color: UIColor? = nil, linkColor: UIColor? = nil) -> NSAttributedString {
        let labelParts = self.components(separatedBy: "_")
        let firstPart = labelParts[0]
        let linkParts = labelParts.indices.contains(1) ? labelParts[1] : ""
        let lastPart = labelParts.indices.contains(2) ? labelParts[2] : ""

        let foregroundColor = color ?? UIColor.black
        let linkSectionColor = linkColor ?? foregroundColor

        let result = NSMutableAttributedString(string: firstPart, attributes: [.foregroundColor: foregroundColor])
        result.append(NSAttributedString(string: linkParts, attributes: [.foregroundColor: linkSectionColor]))
        result.append(NSAttributedString(string: lastPart, attributes: [.foregroundColor: foregroundColor]))

        return result
    }
}
