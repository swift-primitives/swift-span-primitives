// Span.Borrowed.Protocol.swift
//
// Span.Borrowed.`Protocol` is the BORROWED form of the span-vending
// capability: a `~Escapable` type whose value IS a borrow of a contiguous
// region. Its span getter copies `self` (`@_lifetime(copy self)`) — the
// `self` value is the borrow, so the span flows from whatever scope produced
// the conformer.
//
// The owned (`Span.`Protocol``) and borrowed forms cannot be one protocol:
// the witness-table contract for `var span` differs across the two lifetime
// regimes (owned borrows self; borrowed copies self). The split is
// structural. This protocol is the institute-neutral lift of the former
// `__Memory_Contiguous_Borrowed_Protocol`, whose `__`-hoisted name was a
// sibling-resolution workaround now retired (clean SE-0404 nesting works for
// non-generic enum namespaces on the toolchain of record).
//
// THE LINCHPIN: `Swift.Span<Element>` itself conforms to this protocol by
// identity (Swift.Span+Span.Borrowed.Protocol.swift). A span IS the
// borrowed-span capability — so region views can simply BE `Swift.Span`, and
// domain operations attach to bare spans through this protocol with no
// nominal carrier.

public import Span_Primitive

extension Span.Borrowed {
    /// The borrowed span-vending capability.
    ///
    /// A type conforms to `Span.Borrowed.\`Protocol\`` when its value **is** a
    /// borrow of a contiguous region — a `~Copyable & ~Escapable` view whose
    /// `span` getter copies `self` (`@_lifetime(copy self)`). The conformer
    /// cannot be duplicated and cannot outlive the region it borrows; its scope
    /// *is* its lifetime.
    ///
    /// This is the *borrowed* leg of the span capability lattice, the
    /// counterpart to the owned ``Span/Protocol``. The canonical conformer is
    /// `Swift.Span<Element>` itself (by identity) — see the linchpin
    /// conformance below.
    ///
    /// ## Conforming
    ///
    /// A nominal borrowed view stores a `Swift.Span` and forwards it under
    /// `@_lifetime(copy self)`:
    ///
    /// ```swift
    /// public struct MyView: ~Copyable, ~Escapable, Span.Borrowed.`Protocol` {
    ///     @usableFromInline internal let _span: Swift.Span<Element>
    ///     public var span: Swift.Span<Element> {
    ///         @_lifetime(copy self) get { _span }
    ///     }
    ///     @inlinable @_lifetime(borrow span)
    ///     public init(_ span: borrowing Swift.Span<Element>) { self._span = copy span }
    /// }
    /// ```
    ///
    /// ## Conformer guidance — domain-operation extensions MUST restate suppression
    ///
    /// > Important: ANY extension that attaches domain operations to this
    /// > protocol **MUST** restate `where Self: ~Copyable & ~Escapable`.
    /// > Without the restated clause, the extension's `Self` is implicitly
    /// > constrained to `Escapable` (and `Copyable`), so the operations will
    /// > **not** apply to a bare `Swift.Span` (which is `~Escapable`) nor to a
    /// > `~Copyable` borrowed view. The correct shape is:
    /// >
    /// > ```swift
    /// > extension Span.Borrowed.`Protocol` where Self: ~Copyable & ~Escapable, Element == Byte {
    /// >     // byte-domain operations over any borrowed byte span,
    /// >     // including a bare Swift.Span<Byte>
    /// > }
    /// > ```
    /// >
    /// > Domain operations live in the owning domain packages (byte, binary, …)
    /// > in W2 — not here — but the restated-suppression requirement applies
    /// > wherever they are authored.
    ///
    /// ## Topics
    ///
    /// ### Access
    /// - ``span``
    public protocol `Protocol`: ~Copyable, ~Escapable {
        /// The type of element vended through the span.
        associatedtype Element: ~Copyable

        /// A contiguous view of the borrowed region, flowing from `self`.
        ///
        /// The getter copies `self` (`@_lifetime(copy self)`): for a borrowed
        /// view, the `self` value *is* the borrow, so the produced span shares
        /// its lifetime. The canonical conformer `Swift.Span` returns itself.
        var span: Swift.Span<Element> { @_lifetime(copy self) get }
    }
}
