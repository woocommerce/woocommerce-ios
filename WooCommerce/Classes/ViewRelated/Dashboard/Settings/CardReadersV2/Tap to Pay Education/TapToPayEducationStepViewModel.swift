import Foundation

final class TapToPayEducationStepViewModel: ObservableObject {
    let title: String
    let imageName: String
    let descriptionSteps: [String]

    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = Locale.current
        return numberFormatter
    }()

    init(title: String, imageName: String, descriptionSteps: [String]) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = descriptionSteps
    }

    init(title: String, imageName: String, description: String) {
        self.title = title
        self.imageName = imageName
        self.descriptionSteps = [description]
    }

    func format(index: Int) -> String {
        return numberFormatter.string(from: index as NSNumber) ?? "\(index)"
    }
}
