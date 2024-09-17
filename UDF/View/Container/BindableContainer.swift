
import SwiftUI

public protocol BindableContainer: Container, Identifiable {}

public extension BindableContainer {
    @MainActor
    var body: some View {
        let builder = HookBuilder<ContainerState>()
        containerHooks(builder)
        
        return ConnectedContainer<ContainerComponent, ContainerState>(
            containerType: Self.self,
            containerId: { self.id },
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            hooks: builder.build()
        )
    }
}
