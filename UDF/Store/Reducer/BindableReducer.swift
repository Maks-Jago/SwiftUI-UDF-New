//===--- BindableReducer.swift ------------------------------------===//
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

/// A property wrapper that manages a collection of reducers bound to a specific container type.
///
/// `BindableReducer` is designed to automatically manage multiple instances of reducers associated with different instances
/// of a `BindableContainer`. It allows actions to be dispatched and reduced in a dynamic, container-bound manner, facilitating
/// the organization of complex state management in a SwiftUI application.
@propertyWrapper
public struct BindableReducer<BindedContainer: BindableContainer, Reducer: Reducible>: Reducible {
    
    /// A typealias representing a dictionary of reducers associated with container IDs.
    public typealias Reducers = [BindedContainer.ID: Reducer]
    
    /// The type of container this reducer is bound to.
    public internal(set) var containerType: BindedContainer.Type
    
    /// The dictionary holding the reducers associated with each container ID.
    var reducers: Reducers = [:]
    
    /// The wrapped value, which returns `self`.
    public var wrappedValue: BindableReducer<BindedContainer, Reducer> {
        get { self }
        set { /*do nothing*/ }
    }
    
    /// Initializes a new `BindableReducer` with the specified reducer and container types.
    ///
    /// - Parameters:
    ///   - reducerType: The type of reducer to manage.
    ///   - bindedTo: The type of container to bind this reducer to.
    public init(_ reducerType: Reducer.Type, bindedTo: BindedContainer.Type) {
        self.containerType = bindedTo
    }
    
    /// Throws a fatal error. Use `init(reducerType:bindedTo:)` instead.
    public init() {
        fatalError("use init(containerType:reducerType:) instead")
    }
    
    /// Checks for equality between two `BindableReducer` instances by comparing their reducers.
    public static func == (lhs: BindableReducer<BindedContainer, Reducer>, rhs: BindableReducer<BindedContainer, Reducer>) -> Bool {
        lhs.reducers == rhs.reducers
    }
    
    /// Subscript to access the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: The reducer associated with the given container ID, if it exists.
    public subscript(_ id: BindedContainer.ID) -> Reducer? {
        reducers[id]
    }
    
    /// Subscript to access the `Scope` of the reducer associated with the specified container ID.
    ///
    /// - Parameter id: The ID of the container.
    /// - Returns: A `ReducerScope` for the associated reducer, or `nil` if no reducer is found.
    public subscript(_ id: BindedContainer.ID) -> Scope {
        ReducerScope(reducer: reducers[id])
    }
}

// MARK: - Collection Conformance

extension BindableReducer: Collection {
    public typealias Index = Reducers.Index
    public typealias Element = Reducers.Element
    
    /// The starting index of the collection, used in iterations.
    public var startIndex: Index { reducers.startIndex }
    
    /// The ending index of the collection, used in iterations.
    public var endIndex: Index { reducers.endIndex }
    
    /// Required subscript to access an element of the collection at the specified index.
    ///
    /// - Parameter index: The position in the collection.
    /// - Returns: The element at the specified index.
    public subscript(index: Index) -> Reducers.Element {
        reducers[index]
    }
    
    /// Returns the next index in the collection.
    ///
    /// - Parameter i: The current index.
    /// - Returns: The index immediately after the given index.
    public func index(after i: Index) -> Index {
        reducers.index(after: i)
    }
}

// MARK: - Runtime Reducing

extension BindableReducer {
    
    /// Reduces an action by managing its effects on the collection of bound reducers.
    ///
    /// This method handles specific actions to manage the lifecycle of reducers (`_OnContainerDidLoad`, `_OnContainerDidUnLoad`, and `_BindableAction`),
    /// adding, removing, or reducing the appropriate reducers based on the action's type.
    ///
    /// - Parameter action: The action to be reduced.
    mutating public func reduce(_ action: some Action) {
        //TODO: Thinking, should a Bindable Reducer reduce non-bindable actions?
//        for var tuple in reducers {
//            _ = RuntimeReducing.reduce(action, reducer: &tuple.value)
//            reducers.updateValue(tuple.value, forKey: tuple.key)
//        }

        switch action {
        case let action as Actions._OnContainerDidLoad<BindedContainer>:
            reducers[action.id] = .init()
            
        case let action as Actions._OnContainerDidUnLoad<BindedContainer>:
            reducers.removeValue(forKey: action.id)
            
        case let action as Actions._BindableAction<BindedContainer>:
            if var reducer = reducers[action.id] {
                _ = RuntimeReducing.bindableReduce(action.value, reducer: &reducer)
                reducers.updateValue(reducer, forKey: action.id)
            }
            
        default:
            break
        }
    }
}
