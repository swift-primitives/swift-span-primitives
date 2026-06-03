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

public import Span_Primitive

extension Span.Mutable {
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
    ///         mutating get { /* … */ }
    ///     }
    /// }
    /// ```
    ///
    /// ## Composition, not precomposition
    ///
    /// To require *both* a domain core and the mutable span capability, compose
    /// the constraints at the use site
    /// (`some Memory.Contiguous.\`Protocol\` & Span.Mutable.\`Protocol\``)
    /// rather than declaring a precomposed nested protocol
    /// (`Memory.Contiguous.Mutable.\`Protocol\``), per `[API-NAME-002]`.
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
        var mutableSpan: Swift.MutableSpan<Element> { mutating get }
    }
}
