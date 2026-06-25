// Span.Mutable.Protocol.swift
//
// Span.Mutable.`Protocol` refines the owned `Span.`Protocol`` and adds a
// `Swift.MutableSpan` for in-place mutation.
//
// MANDATORY: the refinement MUST restate `~Copyable`
// (`: Span.`Protocol`, ~Copyable`). A bare `protocol `Protocol`: Span.`Protocol``
// re-imposes Copyable on `Self`, because refining a `~Copyable`-allowing
// protocol does NOT propagate the suppression — it must be restated. Without
// it, a `~Copyable` mutable conformer fails to compile (the refinement would
// require `Self: Copyable`, which the conformer cannot satisfy). This mirrors
// the [feedback_extension_implies_copyable] discipline: suppression does not
// flow through refinement; restate it.

public import Index_Primitives
public import Span_Primitive

extension __Span.Mutable {
    /// The mutable span-vending capability.
    ///
    /// Refines ``Span/Protocol`` (the owned read capability) and additionally
    /// vends a `Swift.MutableSpan<Element>` for in-place mutation. A conformer
    /// owns contiguous storage and can both read (`span`, inherited) and mutate
    /// (`mutableSpan`) it.
    ///
    /// ## The restated `~Copyable` (mandatory)
    ///
    /// The declaration restates `~Copyable`:
    ///
    /// ```swift
    /// public protocol `Protocol`: Span.`Protocol`, ~Copyable { … }
    /// ```
    ///
    /// This restatement is **required**, not stylistic. Refining
    /// ``Span/Protocol`` (which allows `~Copyable` `Self`) does not carry the
    /// suppression forward — a bare `: Span.\`Protocol\`` refinement re-imposes
    /// `Self: Copyable`, and a `~Copyable` mutable conformer would then fail to
    /// compile. Suppression must be restated at every refinement that wants to
    /// preserve it.
    ///
    /// ## Conforming
    ///
    /// Provide `span` (the inherited read view) and `mutableSpan`:
    ///
    /// ```swift
    /// extension MyMutableRegion: Span.Mutable.`Protocol` {
    ///     var span: Swift.Span<Element> {
    ///         @_lifetime(borrow self) get { /* … */ }
    ///     }
    ///     var mutableSpan: Swift.MutableSpan<Element> {
    ///         @_lifetime(&self) mutating get { /* … */ }
    ///     }
    /// }
    /// ```
    ///
    /// ## Composition, not precomposition
    ///
    /// To require *both* a domain core and the mutable span capability, compose
    /// the constraints at the use site
    /// (`some Storage.Contiguous.\`Protocol\` & Span.Mutable.\`Protocol\``)
    /// rather than declaring a precomposed nested protocol
    /// (`Storage.Contiguous.Mutable.\`Protocol\``), per `[API-NAME-002]`.
    ///
    /// ## Topics
    ///
    /// ### Access
    /// - ``mutableSpan``
    public protocol `Protocol`: Span.`Protocol`, ~Copyable {
        /// A mutable contiguous view of the conformer's elements.
        ///
        /// Obtained through a `mutating get`: producing the mutable span
        /// requires exclusive access to `self`, which `mutating` enforces.
        /// The `@_lifetime(&self)` annotation states the exclusivity contract
        /// at the declaration, uniform with ``Span/Protocol``'s annotated
        /// `span` requirement. Declaration-side only: probe-proven
        /// insufficient for generic forwarding of `mutableSpan` through a
        /// constrained generic — the no-generic-`mutableSpan` gate is
        /// structural, not conventional.
        var mutableSpan: Swift.MutableSpan<Element> { @_lifetime(&self) mutating get }

        /// A mutable span over the first `count` initialized elements.
        ///
        /// The count-parameterized companion to ``mutableSpan``. A growable discipline
        /// (`Buffer.Linear`/`Buffer.Ring`) is the authority on its live count (its
        /// header), and — unlike the `var mutableSpan` property, whose forwarding through
        /// a constrained generic is borrow-walled (the structural gate documented above)
        /// — a count-*method* CAN be forwarded through a constrained generic. This is the
        /// seam a growable buffer uses to vend a mutable span over an arbitrary mutable
        /// substrate (`Storage<…System>.Contiguous<Element>`, `Store.Small (deferred Q2)`), so growth need not be
        /// pinned to one concrete storage.
        @_lifetime(&self)
        mutating func mutableSpan(count: Index<Element>.Count) -> Swift.MutableSpan<Element>
    }
}
