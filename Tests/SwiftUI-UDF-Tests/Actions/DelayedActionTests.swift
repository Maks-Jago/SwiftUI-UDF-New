
@testable import UDF
import XCTest
import UDFXCTest

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

    func test_WhenActionGroupHasDelay_DataShouldBeUpdatedAfterDelay() async throws {
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
        await fulfill(description: "waiting for delayed action", sleep: 1)

        XCTAssertEqual(store.state.dataForm.title, "delayed title")
        await fulfill(description: "waiting for delayed action", sleep: 1)

        XCTAssertEqual(store.state.dataForm.count, 1)
    }
}
