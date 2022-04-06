//
//  LocationAccessEffect.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI_UDF_Binary

public extension Effects {

    struct LocationAccessEffect: Effectable {
        public init() {}

        public var upstream: AnyPublisher<AnyAction, Never> {
            self.eraseToAnyPublisher()
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: LocationSubscription(subscriber: subscriber))
        }

        private final class LocationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription where S.Input == AnyAction {
            var subscriber: S?

            private let locationManager = CLLocationManager()

            init(subscriber: S) {
                super.init()
                self.subscriber = subscriber
                locationManager.delegate = self
            }

            func request(_ demand: Subscribers.Demand) {
                guard demand > 0 else {
                    return
                }

                send(status: locationManager.authorizationStatus)
            }

            func cancel() {
                subscriber = nil
            }

            func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                send(status: manager.authorizationStatus)
            }

            private func send(status: CLAuthorizationStatus) {
                let action = Actions.DidUpdateLocationAccess(access: status).eraseToAnyAction()
                _ = subscriber?.receive(action)
            }
        }
    }
}
