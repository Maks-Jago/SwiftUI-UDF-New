
@testable import UDF
import UDFXCTest
import XCTest

final class DelayedActionTests: XCTestCase {
    private struct TestStoreLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
            print(
                "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            )
        }
    }

    struct AppState: AppReducer {
        var dataForm = DataForm()
    }

    struct DataForm: Form {
        var title: String = ""
        var count: Int = 0
    }

    func test_WhenActionHasDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.title, value: "delayed title").with(delay: 1))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.title, value: "updated title"))
        await fulfill(description: "waiting for delayed action", sleep: 0.1)

        XCTAssertEqual(store.state.dataForm.title, "updated title")
        await fulfill(description: "waiting for delayed action", sleep: 1)

        XCTAssertEqual(store.state.dataForm.title, "delayed title")
    }

    func test_WhenActionsHaveDelayInGroup_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: "delayed title")
                    .with(delay: 1)

                Actions.UpdateFormField(keyPath: \DataForm.count, value: 1)
                    .with(delay: 2)
            }
        )

        XCTAssertTrue(store.state.dataForm.title.isEmpty)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.title, "delayed title")
        await fulfill(description: "waiting for delayed action", sleep: 1)

        XCTAssertEqual(store.state.dataForm.count, 1)
    }

    func test_WhenActionGroupHasDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: "delayed title")
                Actions.UpdateFormField(keyPath: \DataForm.count, value: 1)
            }
            .with(delay: 1)
        )

        XCTAssertTrue(store.state.dataForm.title.isEmpty)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.title, "delayed title")
        XCTAssertEqual(store.state.dataForm.count, 1)
    }

    func test_WhenSomeActionInGroupHasDelay_OnlyThatActionIsDelayed() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: "delayed title")
                    .with(delay: 1)

                Actions.UpdateFormField(keyPath: \DataForm.count, value: 1)
            }
        )

        XCTAssertEqual(store.state.dataForm.count, 0)
        XCTAssertTrue(store.state.dataForm.title.isEmpty)
        await fulfill(description: "waiting for delayed action", sleep: 0.1)

        XCTAssertEqual(store.state.dataForm.count, 1)
        await fulfill(description: "waiting for delayed action", sleep: 1)
        XCTAssertEqual(store.state.dataForm.title, "delayed title")
    }

    func test_DelayedActionsDDOS() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 1).with(delay: 1))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 2).with(delay: 2))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 3).with(delay: 3))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 4).with(delay: 4))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 5).with(delay: 5))

        XCTAssertEqual(store.state.dataForm.count, 0)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.count, 1)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.count, 2)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.count, 3)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.count, 4)
        await fulfill(description: "waiting for delayed action", sleep: 1.1)

        XCTAssertEqual(store.state.dataForm.count, 5)
    }
}
