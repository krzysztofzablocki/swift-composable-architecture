import Perception

protocol SharedProtocol: AnyObject {
  var didAssert: Bool { get set }
}
enum SharedLocal {
  @TaskLocal static var didSet: ((any SharedProtocol) -> Void)?
}

// TODO: Should we force Value: TestDependencyKey so that we don't get crashes and just
//       get runtime warnings/test failures?
// TODO: make unchecked sendable with a lock
// TODO: Other names: Shared, ObservableRef,
@dynamicMemberLookup
@Perceptible
public final class Shared<Value>: SharedProtocol {
  var didAssert = false
  public func assert(
    _ check: (inout Value) -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) where Value: Equatable {
    var previous = self.snapshot
    check(&previous)
    XCTAssertNoDifference(previous, self.value, file: file, line: line)
    self.didAssert = true
  }

  deinit {
    print("!!!)")
  }

  public var value: Value {
    didSet {
      if let didSet = SharedLocal.didSet {
        didSet(self)
      } else {
        snapshot = value
      }
    }
  }
  var snapshot: Value

  public init(_ value: Value) {
    self.value = value
    self.snapshot = value
  }
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
    get { self.value[keyPath: keyPath] }
    set { self.value[keyPath: keyPath] = newValue }
  }
  public func copy() -> Shared<Value> {
    Shared(self.value)
  }
}
extension Shared: Equatable {
  public static func == (lhs: Shared, rhs: Shared) -> Bool {
    lhs === rhs
  }
}
extension Shared: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
extension Shared: TestDependencyKey {
  public static var testValue: Shared<Value> {
    func open<T: TestDependencyKey>(_: T.Type) -> Value? {
      T.testValue as? Value
    }
    guard
      let key = Value.self as? any TestDependencyKey.Type,
      let value = open(key)
    else { fatalError() }
    return Shared(value)
  }
}
extension Shared: DependencyKey {
  public static var liveValue: Shared<Value> {
    func open<T: DependencyKey>(_: T.Type) -> Value? {
      T.liveValue as? Value
    }
    guard
      let key = Value.self as? any DependencyKey.Type,
      let value = open(key)
    else { fatalError() }
    return Shared(value)
  }
}
// TODO: try reference identity
extension Shared: Identifiable {
  public var id: ObjectIdentifier {
    ObjectIdentifier(self)
  }
}
extension Shared: Decodable where Value: Decodable {
  public convenience init(from decoder: Decoder) throws {
    do {
      self.init(try decoder.singleValueContainer().decode(Value.self))
    } catch {
      self.init(try .init(from: decoder))
    }
  }
}
extension Shared: Encodable where Value: Encodable {
  public func encode(to encoder: Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.value)
    } catch {
      try self.value.encode(to: encoder)
    }
  }
}

@propertyWrapper
public struct Shares<Value> {
  private let _dependency = Dependency(Shared<Value>.self)

  public var wrappedValue: Value {
    get { _dependency.wrappedValue.value }
    set { _dependency.wrappedValue.value = newValue }
  }

  public var projectedValue: Shared<Value> {
    _dependency.wrappedValue
  }

  public init() {}
}
extension Shares: Equatable where Value: Equatable {}
extension Shares: Hashable where Value: Hashable {}
