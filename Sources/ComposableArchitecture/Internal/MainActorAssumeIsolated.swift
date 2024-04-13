@MainActor(unsafe)
func assumeMainActorIsolated<T>(
  _ operation: @MainActor () throws -> T,
  file: StaticString = #fileID,
  line: UInt = #line
) rethrows -> T {
  try operation()
}
