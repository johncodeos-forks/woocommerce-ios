import Foundation
import Combine

final class SimplePaymentsNoteViewModel: EditCustomerNoteViewModelProtocol {

    /// Store for the edited content
    ///
    @Published var newNote: String

    /// Defines the navigation right button state
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Not used.
    ///
    @Published var presentNotice: EditCustomerNoteNotice? = nil

    /// Not used.
    ///
    var presentNoticePublisher: Published<EditCustomerNoteNotice?>.Publisher {
        $presentNotice
    }

    /// Commit the original note.
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) {
        originalNote = newNote
        onFinish(true)

        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowNoteAdded())
    }

    /// Revert to original content.
    ///
    func userDidCancelFlow() {
        newNote = originalNote
    }

    /// Stores the original note content.
    /// Temporarily empty.
    ///
    private var originalNote: String

    /// Analytics engine.
    ///
    private let analytics: Analytics

    init(originalNote: String = "", analytics: Analytics = ServiceLocator.analytics) {
        self.originalNote = originalNote
        self.newNote = originalNote
        self.analytics = analytics
        bindNoteChanges()
    }

    /// Assigns the correct navigation trailing item as the new note content changes.
    ///
    private func bindNoteChanges() {
        $newNote
            .map { editedContent -> EditCustomerNoteNavigationItem in
                .done(enabled: editedContent != self.originalNote)
            }
            .assign(to: &$navigationTrailingItem)
    }
}
