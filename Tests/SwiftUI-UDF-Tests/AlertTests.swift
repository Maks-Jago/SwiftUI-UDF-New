import SwiftUI
@testable import UDF
import XCTest

private extension Actions {
    struct PresentAlertWithAction: Action {}
}

extension AlertBuilder.AlertStyle {
    static func alertWithAction(_ action: @escaping () -> Void) -> Self {
        .init(title: "Custom alert title with action", text: "Custom alert text with action") {
            AlertButton(title: "Action button", action: action)

            AlertButton(title: "Cancel")
                .role(.cancel)
        }
    }
}

final class AlertTests: XCTestCase {
    struct AppState: AppReducer {
        var form = FormWithAlert()
    }

    struct FormWithAlert: UDF.Form {
        enum AlertId: Hashable {
            case alertWithAction
        }

        var alert: AlertBuilder.AlertStatus = .dismissed

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.PresentAlertWithAction:
                alert = .init(id: AlertId.alertWithAction)

            default:
                break
            }
        }
    }

    func test_WhenAlerBuilderRegistered_AlertCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.alert.status

        XCTAssertEqual(status, .dismissed)

        AlertBuilder.registerAlert(by: FormWithAlert.AlertId.alertWithAction) {
            .alertWithAction {
                print("Custom alert action")
            }
        }

        await store.dispatch(Actions.PresentAlertWithAction())
        status = await store.state.form.alert.status

        XCTAssertNotEqual(status, .dismissed)
    }
}
