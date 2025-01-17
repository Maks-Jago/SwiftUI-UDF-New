//===--- Action.swift ---------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A protocol representing an action in the Unidirectional Data Flow (UDF) architecture.
/// Actions are responsible for describing state changes and can be dispatched to reducers.
///
/// Conforming to `Action` allows the creation of custom actions that are equatable,
/// making it easier to manage state updates in a predictable manner.
public protocol Action: Equatable {}

public extension Action {
    /// Associates an animation with the action.
    ///
    /// - Parameter animation: The `Animation` to associate with the action.
    /// - Returns: A new `Action` wrapped in an `ActionGroup` with the specified animation.
    ///
    /// Example:
    /// ```swift
    /// let action = MyAction().with(animation: .easeIn)
    /// ```
    func with(
        animation: Animation?,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> some Action {
        if let group = self as? ActionGroup {
            ActionGroup(internalActions: group._actions.map { oldAction in
                var mutableCopy = oldAction
                mutableCopy.animation = animation
                return mutableCopy
            })
        } else {
            ActionGroup(internalActions: [
                InternalAction(
                    self,
                    animation: animation,
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                ),
            ])
        }
    }
}

public extension Action {
    /// Marks the action as silent, indicating it should not trigger side effects like logging.
    ///
    /// - Returns: A new `Action` wrapped in an `ActionGroup` marked as silent.
    ///
    /// Example:
    /// ```swift
    /// let action = MyAction().silent()
    /// ```
    func silent(fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) -> some Action {
        if let group = self as? ActionGroup {
            ActionGroup(internalActions: group._actions.map { oldAction in
                var mutableCopy = oldAction
                mutableCopy.silent = true
                return mutableCopy
            })
        } else {
            ActionGroup(internalActions: [
                InternalAction(
                    self,
                    silent: true,
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                ),
            ])
        }
    }
}

public extension Action {
    /// Binds the action to a specific `BindableContainer` by its type and identifier.
    ///
    /// - Parameters:
    ///   - containerType: The type of the `BindableContainer` to bind to.
    ///   - id: The identifier of the item instance.
    /// - Returns: A new `Action` wrapped in an `ActionGroup` bound to the specified container.
    ///
    /// Example:
    /// ```swift
    /// let action = MyAction().binded(to: MyContainer.self, by: itemId)
    /// ```
    func binded<BindedContainer: BindableContainer>(
        to containerType: BindedContainer.Type,
        by id: BindedContainer.ID,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> some Action {
        if let group = self as? ActionGroup {
            ActionGroup(internalActions: group._actions.map { oldAction in
                InternalAction(
                    oldAction.value.binded(to: containerType, by: id),
                    animation: oldAction.animation,
                    silent: oldAction.silent,
                    fileName: oldAction.fileName,
                    functionName: oldAction.functionName,
                    lineNumber: oldAction.lineNumber
                )
            })
        } else {
            ActionGroup(internalActions: [
                InternalAction(
                    Actions._BindableAction(
                        value: self,
                        containerType: containerType,
                        id: id
                    ),
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                ),
            ])
        }
    }

    /// Binds the action to a specific `BindableContainer` instance.
    ///
    /// - Parameter container: The `BindableContainer` instance to bind to.
    /// - Returns: A new `Action` bound to the specified container instance.
    ///
    /// Example:
    /// ```swift
    /// let action = MyAction().binded(to: myContainer)
    /// ```
    func binded<BindedContainer: BindableContainer>(
        to container: BindedContainer,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> some Action {
        binded(
            to: BindedContainer.self,
            by: container.id,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
}

public extension Action {
    func with(
        delay: TimeInterval,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> some Action {
        if let group = self as? ActionGroup {
            ActionGroup(internalActions: group._actions.map { oldAction in
                var mutableCopy = oldAction
                mutableCopy.delay = Delay(delay)
                return mutableCopy
            })
        } else {
            ActionGroup(internalActions: [
                InternalAction(
                    self,
                    delay: Delay(delay),
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                ),
            ])
        }
    }
}
