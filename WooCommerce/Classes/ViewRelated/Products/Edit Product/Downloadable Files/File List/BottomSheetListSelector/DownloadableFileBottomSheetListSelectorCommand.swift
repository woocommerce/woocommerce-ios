import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a form action for adding a new Downloadable File.
///
final class DownloadableFileBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    var data: [DownloadableFileFormBottomSheetAction]

    var selected: DownloadableFileFormBottomSheetAction?

    typealias Model = DownloadableFileFormBottomSheetAction
    typealias Cell = ImageAndTitleAndTextTableViewCell

    private let onSelection: (DownloadableFileFormBottomSheetAction) -> Void

    init(actions: [DownloadableFileFormBottomSheetAction],
         onSelection: @escaping (DownloadableFileFormBottomSheetAction) -> Void) {
        self.onSelection = onSelection
        self.data = actions
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: DownloadableFileFormBottomSheetAction) {
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

    func handleSelectedChange(selected: DownloadableFileFormBottomSheetAction) {
        onSelection(selected)
    }

    func isSelected(model: DownloadableFileFormBottomSheetAction) -> Bool {
        return model == selected
    }
}
