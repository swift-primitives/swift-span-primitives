// Span.Mutable.swift

extension Span {
    /// Namespace for the mutable (owned-`Self`) span capability.
    ///
    /// Houses ``Span/Mutable/Protocol`` — a refinement of ``Span/Protocol``
    /// that additionally vends a `Swift.MutableSpan` for in-place mutation.
    public enum Mutable {}
}
