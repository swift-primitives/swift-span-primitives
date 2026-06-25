// Span.Protocol.swift
//
// Span.`Protocol` is the UNIFIED span-vending capability: a type that can
// produce a `Swift.Span` over its contiguous elements — whether it OWNS the
// storage (an Escapable container that COMPUTES a span borrowing itself) or
// IS the borrow (a `~Copyable & ~Escapable` view, canonically a bare
// `Swift.Span` itself).
//
// `Self` suppresses BOTH `Copyable` and `Escapable`; the single requirement
// is `span` under `@_lifetime(borrow self)` — the one lifetime contract
// expressible by both worlds. `@_lifetime(copy self)` is owned-unsatisfiable
// ("cannot copy the lifetime of an Escapable type") and a no-annotation
// requirement is rejected at the protocol declaration, so `borrow self` is
// the unique unifier. Empirically proven on Swift 6.3.2 (all four conformer
// shapes; cursor hot path 0-`witness_method` cross-module, byte-identical to
// the two-protocol baseline): `/tmp/msb-span-unify`, receipt
// `Outputs/UNIFY-RECEIPT.md`.
//
// This collapses the former two-protocol lattice (owned `Span.`Protocol`` +
// `Span.Borrowed.`Protocol``). The old claim — "the witness-table contract
// for `var span` differs across the two lifetime regimes", inherited from
// `__Memory_Contiguous_Borrowed_Protocol` — is REFUTED for the `borrow self`
// form: escapability is an orthogonal property of the conformer, not a fork
// in the capability.
//
// Heritage: the institute-neutral lift of a former Memory-namespace
// contiguous-access protocol, renamed and relocated here so byte/binary/memory
// each conform without a cross-domain edge (see
// swift-institute/Research/memory-byte-bit-domain-orthogonality.md and
// cross-layer-capability-protocol-model.md §12), subsequently unified with
// its borrowed counterpart.

public import Span_Primitive

extension __Span {
    /// The span-vending capability.
    ///
    /// A type conforms to `Span.\`Protocol\`` when it can produce a
    /// `Swift.Span<Element>` over its contiguous elements. `Self` suppresses
    /// both `Copyable` and `Escapable`, so the capability is satisfied by
    /// **both** lifetime regimes:
    ///
    /// - **Owned** (Escapable) conformers — containers that own contiguous
    ///   storage and compute a span borrowing themselves
    ///   (`Storage.Contiguous<Memory.Heap>`, the array/buffer families, …).
    /// - **Borrowed** (`~Escapable`) conformers — views whose value *is* a
    ///   borrow of a region. The canonical conformer is `Swift.Span<Element>`
    ///   itself, by identity (see the linchpin conformance,
    ///   `Swift.Span+Span.Protocol.swift`).
    ///
    /// The single requirement, `span`, is annotated `@_lifetime(borrow self)`
    /// — the one contract both regimes can witness: an owned type borrows
    /// itself for the span's lifetime; a borrowed view's `self` *is* the
    /// borrow it forwards.
    ///
    /// Its mutable refinement is ``Span/Mutable/Protocol``.
    ///
    /// ## Conforming — owned
    ///
    /// Compute the span from your storage under `@_lifetime(borrow self)`:
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
    /// ## Conforming — borrowed
    ///
    /// A nominal borrowed view stores a `Swift.Span` and forwards it:
    ///
    /// ```swift
    /// public struct MyView: ~Copyable, ~Escapable, Span.`Protocol` {
    ///     @usableFromInline internal let _span: Swift.Span<Element>
    ///     public var span: Swift.Span<Element> {
    ///         @_lifetime(borrow self) get { _span }
    ///     }
    ///     @inlinable @_lifetime(borrow span)
    ///     public init(_ span: borrowing Swift.Span<Element>) { self._span = copy span }
    /// }
    /// ```
    ///
    /// Raw-pointer access for C interop derives from the vended span
    /// (`span.withUnsafeBufferPointer { … }`); the protocol's sole requirement
    /// is `span`.
    ///
    /// ## Suppression must be restated at every use site that wants it
    ///
    /// > Important: ANY extension that attaches domain operations to this
    /// > protocol — and any generic constraint that should admit `~Escapable`
    /// > conformers (a bare `Swift.Span`) — **MUST** restate
    /// > `Self: ~Copyable & ~Escapable` (resp. `& ~Copyable & ~Escapable` on
    /// > the generic parameter). Without the restated clause, `Self` is
    /// > implicitly constrained to `Escapable` (and `Copyable`), so the
    /// > operations will **not** apply to a bare span nor to a `~Copyable`
    /// > view. The correct shape is:
    /// >
    /// > ```swift
    /// > extension Span.`Protocol` where Self: ~Copyable & ~Escapable, Element == Byte {
    /// >     // byte-domain operations over ANY byte-span capability,
    /// >     // including a bare Swift.Span<Byte>
    /// > }
    /// > ```
    /// >
    /// > Conversely, a constraint site that *stores* a conformer by value in
    /// > an Escapable type (an owned cursor, a buffer) simply omits the
    /// > suppression — the implicit `Escapable` default on the generic
    /// > parameter is the escapability assertion, now located at the
    /// > by-value-storage site rather than in the protocol.
    ///
    /// ## Topics
    ///
    /// ### Access
    /// - ``span``
    public protocol `Protocol`: ~Copyable, ~Escapable {
        /// The type of element vended through the span.
        associatedtype Element: ~Copyable

        /// A contiguous view of the conformer's elements, borrowing `self`.
        ///
        /// The returned span borrows `self` for its lifetime
        /// (`@_lifetime(borrow self)`): an owned conformer cannot be moved or
        /// mutated while the span is live; a borrowed conformer forwards the
        /// borrow it already is. Safe for both heap and inline storage.
        var span: Swift.Span<Element> { @_lifetime(borrow self) get }
    }
}
