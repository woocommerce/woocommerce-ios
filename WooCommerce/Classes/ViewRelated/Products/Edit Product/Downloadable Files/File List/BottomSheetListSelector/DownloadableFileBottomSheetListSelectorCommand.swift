import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a form action for adding a new Downloadable File.
///
final class DownloadableFileBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    let data: [DownloadableFileSource]

    var selected: DownloadableFileSource?

    typealias Model = DownloadableFileSource
    typealias Cell = ImageAndTitleAndTextTableViewCell

    private let onSelection: (DownloadableFileSource) -> Void

    init(actions: [DownloadableFileSource],
         onSelection: @escaping (DownloadableFileSource) -> Void) {
        self.onSelection = onSelection
        self.data = actions
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: DownloadableFileSource) {
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.title,
                                                                    text: nil,
                                                                    textTintColor: .text,
                                                                    image: model.image,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: DownloadableFileSource) {
        onSelection(selected)
    }

    func isSelected(model: DownloadableFileSource) -> Bool {
        return model == selected
    }
}
