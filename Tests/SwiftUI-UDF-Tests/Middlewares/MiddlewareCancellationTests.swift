
import Combine
@testable import UDF
import UDFXCTest
import XCTest

final class MiddlewareCancellationTests: XCTestCase {
    struct AppState: AppReducer {
        var middlewareFlow = MiddlewareFlow()
        var runForm = RunForm()
    }

    enum MiddlewareFlow: IdentifiableFlow {
        case none, loading, cancel, message

        init() { self = .none }

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidCancelEffect where action.cancellation == ObservableMiddlewareToCancel.Сancellation.message:
                self = .none

            case let action as Actions.DidCancelEffect
                where action.cancellation == ReducibleMiddlewareToCancel.Сancellation.reducibleMessage:
                self = .none

            case let action as Actions.DidCancelEffect where action.cancellation == ObservableRunMiddlewareToCancel.Сancellation.runMessage:
                self = .none

            case is Actions.Loading:
                self = .loading

            case is Actions.CancelLoading:
                self = .cancel

            case is Actions.Message:
                self = .message

            default:
                break
            }
        }
    }

    struct RunForm: Form {
        var messagesCount: Int = 0

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.Message:
                messagesCount += 1

            default:
                break
            }
        }
    }

    func testObservableMiddlewareCancellation() async {
        let store = await XCTestStore(initial: AppState())

        await store.subscribe(ObservableMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .loading)

        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .none)
    }

    func testObservableRunMiddlewareToCancel() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(ObservableRunMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .loading)

        await fulfill(description: "waiting for messages to increase messages count in form", sleep: 2)
        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        let messagesCount = await store.state.runForm.messagesCount
        XCTAssertGreaterThanOrEqual(messagesCount, 1)

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .none)
    }

    func testReducibleMiddlewareToCancel() async {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(ReducibleMiddlewareToCancel.self)
        await store.dispatch(Actions.Loading())

        var middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .loading)

        await store.dispatch(Actions.CancelLoading())
        await store.wait()

        middlewareFlow = await store.state.middlewareFlow
        XCTAssertEqual(middlewareFlow, .none)
    }
}

private extension Actions {
    struct Loading: Action {}
    struct CancelLoading: Action {}
}

// MARK: - Middlewares
private extension MiddlewareCancellationTests {
    final class ObservableMiddlewareToCancel: BaseObservableMiddleware<AppState> {
        var environment: Void!

        enum Сancellation: CaseIterable {
            case message
        }

        func scope(for state: MiddlewareCancellationTests.AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: MiddlewareCancellationTests.AppState) {
            switch state.middlewareFlow {
            case .loading:
                execute(
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.message
                )

            case .cancel:
                cancel(by: Сancellation.message)

            default:
                break
            }
        }
    }

    final class ObservableRunMiddlewareToCancel: BaseObservableMiddleware<AppState> {
        struct Environment {}

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Сancellation: CaseIterable {
            case runMessage
        }

        func scope(for state: MiddlewareCancellationTests.AppState) -> Scope {
            state.middlewareFlow
        }

        func observe(state: MiddlewareCancellationTests.AppState) {
            switch state.middlewareFlow {
            case .loading:
                run(RunEffect(), cancellation: Сancellation.runMessage)

            case .cancel:
                cancel(by: Сancellation.runMessage)

            default:
                break
            }
        }

        struct RunEffect: Effectable {
            var upstream: AnyPublisher<any Action, Never> {
                Timer.publish(every: 1, on: RunLoop.main, in: .default)
                    .autoconnect()
                    .flatMap { _ in
                        Future<any Action, Never> { promise in
                            promise(.success(Actions.Message(id: "message_id")))
                        }
                        .receive(on: DispatchQueue.main)
                    }
                    .eraseToAnyPublisher()
            }
        }
    }

    final class ReducibleMiddlewareToCancel: BaseReducibleMiddleware<AppState> {
        struct Environment {}

        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment()
        }

        enum Сancellation: CaseIterable {
            case reducibleMessage
        }

        func reduce(_ action: some Action, for state: MiddlewareCancellationTests.AppState) {
            switch action {
            case is Actions.Loading:
                execute(
                    Effect(action: Actions.Message(id: "message_id")).delay(duration: 1, queue: queue),
                    cancellation: Сancellation.reducibleMessage
                )

            case is Actions.CancelLoading:
                cancel(by: Сancellation.reducibleMessage)

            default:
                break
            }
        }
    }
}
