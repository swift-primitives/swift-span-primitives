// Span.Protocol.swift
//
// Span.`Protocol` is the OWNED form of the span-vending capability: a type
// that OWNS its contiguous storage and can COMPUTE a `Swift.Span` borrowing
// itself. `Self` is Escapable (the default) — the value outlives any single
// span it produces, so the span getter borrows `self`
// (`@_lifetime(borrow self)`).
//
// This is the institute-neutral lift of the former
// `Memory.Contiguous.Protocol` (the `Memory.ContiguousProtocol` declaration):
// renamed and relocated out of the Memory namespace so byte/binary/memory
// each conform without a cross-domain edge. See
// swift-institute/Research/memory-byte-bit-domain-orthogonality.md and
// cross-layer-capability-protocol-model.md §12.

public import Span_Primitive

extension Span {
    /// The owned span-vending capability.
    ///
    /// A type conforms to `Span.\`Protocol\`` when it **owns** contiguous
    /// storage and can produce a `Swift.Span<Element>` that borrows `self`.
    /// `Self` is Escapable: the conformer outlives the spans it vends, and the
    /// `@_lifetime(borrow self)` annotation binds each produced span to the
    /// lifetime of the borrow.
    ///
    /// This is the *owned* leg of the span capability lattice. Its borrowed
    /// counterpart is ``Span/Borrowed/Protocol`` (for `~Escapable` types whose
    /// value *is* the borrow); its mutable refinement is
    /// ``Span/Mutable/Protocol``.
    ///
    /// ## Conforming
    ///
    /// Provide the single requirement, `span`, computing it from your storage
    /// under `@_lifetime(borrow self)`:
    ///
    /// ```swift
    /// extension MyOwnedRegion: Span.`Protocol` {
    ///     var span: Swift.Span<Element> {
    ///         @_lifetime(borrow self)
    ///         get {
    ///             let ptr = /* pointer to storage */
    ///             let raw = Swift.Span(_unsafeStart: ptr, count: count)
    ///             return _overrideLifetime(raw, borrowing: self)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Raw-pointer access for C interop derives from the vended span
    /// (`span.withUnsafeBufferPointer { … }`); the protocol's sole requirement
    /// is `span`.
    ///
    /// ## Domain operations
    ///
    /// Domain-specific operations over an owned span attach via constrained
    /// extensions, e.g. `extension Span.\`Protocol\` where Element == Byte`.
    /// Such extensions need no special suppression clause (unlike
    /// ``Span/Borrowed/Protocol``, whose extensions MUST restate
    /// `Self: ~Copyable & ~Escapable`).
    ///
    /// ## Topics
    ///
    /// ### Access
    /// - ``span``
    public protocol `Protocol`: ~Copyable {
        /// The type of element vended through the span.
        associatedtype Element: ~Copyable

        /// A contiguous view of the conformer's elements, borrowing `self`.
        ///
        /// The returned span borrows `self` for its lifetime
        /// (`@_lifetime(borrow self)`), preventing the conformer from being
        /// moved or mutated while the span is live. Safe for both heap and
        /// inline storage.
        var span: Swift.Span<Element> { @_lifetime(borrow self) get }
    }
}
