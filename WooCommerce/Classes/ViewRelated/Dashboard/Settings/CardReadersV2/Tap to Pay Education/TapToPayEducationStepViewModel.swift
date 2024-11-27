import Foundation

final class TapToPayEducationStepViewModel {
    let title: String
    let imageName: String
    let descriptionSteps: [String]

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
}
