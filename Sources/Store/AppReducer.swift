//
//  StateReducer.swift
//  
//
//  Created by Max Kuznetsov on 22.07.2021.
//

import Foundation
import Runtime

//public struct StateReducer<State: Reducible> {
//
//    public func callAsFunction(_ state: inout State, _ action: AnyAction) {
//        #if DEBUG
//        print("Reduce\t\t\t", action)
//        print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
//        #endif
//        state.reduce(action)
//    }
//}

extension AppReducer {
    public mutating func reduce(_ action: AnyAction) -> Bool {
        let info = try! typeInfo(of: Self.self)

        var mutaded = false

        for property in info.properties {
            guard let reducer = try? property.get(from: self) as? Reducing else {
                continue
            }

            var mutableReducer = reducer
            mutableReducer.reduce(action)

            if !mutableReducer.isEqual(reducer) {
                try? property.set(value: mutableReducer, on: &self)
                mutaded = true
            }
        }

        return mutaded
    }
}