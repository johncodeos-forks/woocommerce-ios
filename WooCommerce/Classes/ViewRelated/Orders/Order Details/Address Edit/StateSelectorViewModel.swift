import Combine
import SwiftUI

/// View Model for the `StateSelector` view.
///
final class StateSelectorViewModel: FilterListSelectorViewModelable, ObservableObject {

    /// Current search term entered by the user.
    /// Each update will trigger an update to the `command` that contains the state data.
    var searchTerm: String = "" {
        didSet {
            command.filterStates(term: searchTerm)
            objectWillChange.send()
        }
    }

    /// Command that powers the `ListSelector` view.
    ///
    let command = StateSelectorCommand()

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

    /// States do not require data loading
    ///
    let showPlaceholders = false
}

// MARK: Constants
private extension StateSelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("State", comment: "Title to select state from the edit address screen")
        static let placeholder = NSLocalizedString("Filter States", comment: "Placeholder on the search field to search for a specific state")
    }
}