//===--- DefaultActionFilter.swift ---------------------------------------===//
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

/// An action filter that includes actions based on their `silent` property.
/// If the action is marked as `silent`, it will be excluded from filtering; otherwise, it will be included.
public struct DefaultActionFilter: ActionFilter {
    /// Initializes a new `DefaultActionFilter`.
    public init() {}

    /// Determines whether a given action should be included.
    ///
    /// - Parameter action: The action to be evaluated.
    /// - Returns: `false` if the action is marked as `silent` or is of type `_AnyBindableAction`; `true` otherwise.
    public func include(action: LoggingAction) -> Bool {
        switch action.internalAction.value {
        case _ as any _AnyBindableAction: false
        default: action.internalAction.silent == false
        }
    }
}

public extension ActionFilter where Self == DefaultActionFilter {
    /// A static property that provides the default action filter.
    static var `default`: ActionFilter { DefaultActionFilter() }
}
