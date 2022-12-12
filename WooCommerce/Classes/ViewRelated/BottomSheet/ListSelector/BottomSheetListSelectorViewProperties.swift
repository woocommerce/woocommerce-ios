/// Properties for the bottom sheet list selector view.
///
struct BottomSheetListSelectorViewProperties {
    let title: String?
    let subtitle: String?

    init(title: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}
