// Span.Borrowed.swift

extension Span {
    /// Namespace for the borrowed (`~Escapable`-`Self`) span capability.
    ///
    /// Houses ``Span/Borrowed/Protocol`` — the capability of a `~Escapable`
    /// type whose value *is* a borrow of a contiguous region, so its span
    /// getter copies `self` (`@_lifetime(copy self)`) rather than borrowing it.
    public enum Borrowed {}
}
