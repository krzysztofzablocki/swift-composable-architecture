import Foundation

public struct LifetimeTrackingInstrumentation {
    public static var shared: LifetimeTrackingInstrumentation?

    public var onStoreCreated: (_ file: StaticString, _ function: StaticString, _ line: UInt, _ store: AnyObject) -> Void

    public init(onStoreCreated: @escaping (_: StaticString, _: StaticString, _ line: UInt, _ store: AnyObject) -> Void) {
        self.onStoreCreated = onStoreCreated
    }
}

