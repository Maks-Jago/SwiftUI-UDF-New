//
//  ActionGroupBuilderTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 18.09.2022.
//

@testable import UDF
import XCTest

final class ActionGroupBuilderTests: XCTestCase {
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let group = ActionGroup {
            ()
        }

        XCTAssertTrue(group.actions.isEmpty, "An ActionGroup shouldn't have action when there is some Void in the builder")
    }

    func test_WhenConditionFalse_ActionGroupShouldBeEmpty() {
        let condition = false

        let group = ActionGroup {
            if condition {
                Actions.Message(message: "m1", id: "m1")
            }
        }

        XCTAssertTrue(group.actions.isEmpty)
    }

    func test_WhenConditionTrue_ActionGroupShouldNotBeEmpty() {
        let condition = true

        let group = ActionGroup {
            if condition {
                Actions.Message(message: "m1", id: "m1")
            }
        }

        XCTAssertFalse(group.actions.isEmpty)
    }

    func test_WhenConditionFalseWithPrefixAction_ActionGroupShouldHaveOneAction() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            }
        }

        XCTAssertEqual(group.actions.count, 1)
    }

    func test_WhenElseConditionFalseWithPrefixAction_ActionGroupShouldHaveTwoActions() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            } else {
                Actions.Message(message: "m3", id: "m3")
            }
        }

        XCTAssertEqual(group.actions.count, 2)
    }

    func test_WhenIfElseConditionFalseWithPrefixAction_ActionGroupShouldHaveTwoActions() {
        let condition = false

        let group = ActionGroup {
            Actions.Message(message: "m1", id: "m1")

            if condition {
                Actions.Message(message: "m2", id: "m2")
            } else if condition == false {
                Actions.Message(message: "m3", id: "m3")
            } else {
                Actions.Message(message: "m4", id: "m3")
            }
        }

        XCTAssertEqual(group.actions.count, 2)
    }

    func test_Switch() {
        let value = 4

        let group = ActionGroup {
            switch value {
            case 0:
                Actions.Message(message: "m0", id: "m0")

            case 1 ... 4:
                Actions.Message(message: "m4", id: "m4")

            case 4...:
                Actions.Message(message: "m5", id: "m5")

            default:
                ()
            }
        }

        XCTAssertEqual(group.actions.count, 1)
    }

    func test_Loop() {
        let group = ActionGroup {
            for i in 0 ... 3 {
                Actions.Message(message: "m\(i)", id: "m\(i)")
            }

            Actions.Message(message: "m5", id: "m5")
        }

        XCTAssertEqual(group.actions.count, 5)
    }

    func test_OptionalAction() {
        let optionalActionWithValue: (any Action)? = Actions.Message(message: "m1", id: "m1")
        let optionalActionNil: (any Action)? = nil

        let group = ActionGroup {
            optionalActionWithValue
            optionalActionNil
        }

        XCTAssertEqual(group.actions.count, 1)
    }
}
