import Foundation
import XCTest
import Combine

@testable import WooCommerce
@testable import Yosemite

final class SimplePaymentsMethodsViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_loading_is_enabled_while_marking_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores)

        // When
        let loadingStates: [Bool] = waitFor { promise in
            viewModel.$showLoadingIndicator
                .dropFirst() // Initial value
                .collect(2)  // Collect toggle
                .first()
                .sink { loadingStates in
                    promise(loadingStates)
                }
                .store(in: &self.subscriptions)
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertEqual(loadingStates, [true, false]) // Loading, then not loading.
    }

    func test_view_is_disabled_while_loading_is_enabled() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores)

        // When
        let loading: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrderStatus:
                    promise(viewModel.showLoadingIndicator)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(loading)
        XCTAssertTrue(viewModel.disableViewActions)
    }

    func test_onSuccess_is_invoked_after_order_is_marked_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let onSuccessInvoked: Bool = waitFor { promise in
            viewModel.markOrderAsPaid(onSuccess: {
                promise(true)
            })
        }

        // Then
        XCTAssertTrue(onSuccessInvoked)
    }

    func test_view_model_attempts_completed_notice_presentation_when_marking_an_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", presentNoticeSubject: noticeSubject, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let receivedCompleted: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error:
                    promise(false)
                case .completed:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_attempts_error_notice_presentation_when_failing_to_mark_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", presentNoticeSubject: noticeSubject, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(NSError(domain: "Error", code: 0))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let receivedError: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error:
                    promise(true)
                case .completed:
                    promise(false)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(receivedError)
    }

    func test_completed_event_is_tracked_after_marking_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.markOrderAsPaid(onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.simplePaymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
    }

    func test_failed_event_is_tracked_after_failing_to_mark_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(NSError(domain: "", code: 0, userInfo: nil))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.markOrderAsPaid(onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.simplePaymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.first?["source"] as? String, "payment_method")
    }

    func test_collect_event_is_tracked_when_required() {
        // Given
        let analytics = MockAnalyticsProvider()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackCollectByCash()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.simplePaymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
    }

    func test_collect_event_is_tracked_when_collecting_payment() {
        // Given
        let analytics = MockAnalyticsProvider()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", stores: stores, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.collectPayment(on: UIViewController(), onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.simplePaymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "card")
    }

    func test_card_row_is_shown_for_cpp_store() {
        // Given
        let cppStateObserver = MockCardPresentPaymentsOnboardingUseCase(initial: .completed)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", cppStoreStateObserver: cppStateObserver)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_for_non_cpp_store() {
        // Given
        let cppStateObserver = MockCardPresentPaymentsOnboardingUseCase(initial: .wcpayNotInstalled)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", cppStoreStateObserver: cppStateObserver)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_card_row_state_changes_when_store_state_changes() {
        // Given
        let subject = PassthroughSubject<CardPresentPaymentOnboardingState, Never>()
        let cppStateObserver = MockCardPresentPaymentsOnboardingUseCase(initial: .wcpayNotInstalled, publisher: subject.eraseToAnyPublisher())
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00", cppStoreStateObserver: cppStateObserver)
        XCTAssertFalse(viewModel.showPayWithCardRow)

        // When
        subject.send(.completed)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
    }
}