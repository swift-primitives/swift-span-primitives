// Span.swift

/// The span-vending capability domain.
///
/// `Span` answers "what can vend a contiguous view of its elements?" — a
/// *capability*, not a storage strategy and not a location. It is the
/// namespace-neutral home for the protocols a type conforms to in order to
/// expose a `Swift.Span` / `Swift.MutableSpan` over its elements, regardless
/// of which domain the type belongs to (memory regions, byte streams, binary
/// buffers, …).
///
/// The capability is deliberately **decoupled from any single domain
/// namespace**. A `Memory.Contiguous` vends a span; a contiguous `Storage`
/// vends a span; a `Byte.Borrowed` vends a span; a `Binary.Borrowed` vends a
/// span. Naming the protocol after any one of those domains
/// (e.g. `Memory.Contiguous.Borrowed.Protocol`) is what couples the other
/// domains to it. Hosting the capability here — in a tier-0 package over the
/// stdlib `Swift.Span` family alone — lets each domain conform independently
/// with no cross-domain edge.
///
/// ## Capability lattice
///
/// The capability splits along the **lifetime regime** of the conforming
/// `Self`, because `Swift.Span` is `~Escapable` and a conformer either
/// *computes* a span borrowing `self` (owned) or *is* the borrow
/// (`~Escapable`):
///
/// | Protocol | `Self` | Vends | Lifetime |
/// |----------|--------|-------|----------|
/// | ``Span/Protocol`` | owned (Escapable) | `Span<Element>` | `@_lifetime(borrow self)` |
/// | ``Span/Borrowed/Protocol`` | `~Escapable` | `Span<Element>` | `@_lifetime(copy self)` |
/// | ``Span/Mutable/Protocol`` | owned (Escapable) | `Span` + `MutableSpan` | refines ``Span/Protocol`` |
///
/// The owned and borrowed forms cannot be one protocol — the witness-table
/// contract for `var span` differs across the two lifetime regimes (the owned
/// getter borrows `self`; the borrowed getter copies `self`, which *is* the
/// borrow). The split is structural, not stylistic.
///
/// ## The linchpin conformance
///
/// `Swift.Span<Element>` itself conforms to ``Span/Borrowed/Protocol`` by
/// identity (`var span { self }`) — a span *is* the borrowed-span capability.
/// This is what lets domain operations attach to bare `Swift.Span` values
/// through the capability without a nominal wrapper.
///
/// ## Deferred sub-namespaces
///
/// `Span.Raw[.Mutable]` (over `RawSpan` / `MutableRawSpan`) and
/// `Span.Output[.Raw]` (over `OutputSpan` / `OutputRawSpan`) follow the same
/// `Nest.Name` shape and are **deferred** — they ship when a conformer needs
/// them, per the orthogonality doc's "ship as needed" disposition. This
/// package currently ships only the typed-element lattice (``Span/Protocol``,
/// ``Span/Borrowed/Protocol``, ``Span/Mutable/Protocol``).
///
/// - SeeAlso: `swift-institute/Research/memory-byte-bit-domain-orthogonality.md`,
///   `swift-institute/Research/cross-layer-capability-protocol-model.md` §12.
public enum Span {}
