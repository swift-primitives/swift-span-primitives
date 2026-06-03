# ``Span_Primitives``

The span-vending capability: namespace-neutral protocols for types that expose
a contiguous `Swift.Span` / `Swift.MutableSpan` over their elements.

## Overview

`swift-span-primitives` is a tier-0 capability package over the Swift standard
library's `Span` family. It owns the protocols a type conforms to in order to
vend a contiguous view of its elements — independent of which domain the type
belongs to (memory regions, byte streams, binary buffers, …).

"Vending a contiguous view" is a *capability*, not a location or a storage
strategy. Hosting it here, decoupled from any single domain namespace, lets
each domain conform to the same capability with no cross-domain dependency edge
— the resolution to the byte/binary ↔ memory coupling identified in
`memory-byte-bit-domain-orthogonality.md` and folded into
`cross-layer-capability-protocol-model.md` §12.

## The capability lattice

The capability splits along the lifetime regime of the conforming `Self`,
because `Swift.Span` is `~Escapable`:

- ``Span/Protocol`` — **owned** (Escapable `Self`): the conformer owns storage
  and *computes* a span borrowing `self` (`@_lifetime(borrow self)`).
- ``Span/Borrowed/Protocol`` — **borrowed** (`~Copyable & ~Escapable` `Self`):
  the conformer's value *is* the borrow; its span getter copies `self`
  (`@_lifetime(copy self)`). `Swift.Span` itself conforms by identity — the
  linchpin.
- ``Span/Mutable/Protocol`` — **mutable**: refines ``Span/Protocol`` and adds
  `mutableSpan: Swift.MutableSpan<Element>` (restating `~Copyable`).

Owned and borrowed are distinct protocols because the witness-table contract
for `var span` differs across the two lifetime regimes; the split is
structural.

## Deferred

`Span.Raw[.Mutable]` (over `RawSpan` / `MutableRawSpan`) and
`Span.Output[.Raw]` (over `OutputSpan` / `OutputRawSpan`) follow the same
`Nest.Name` shape and are **deferred** — they ship when a concrete conformer
needs them, per the orthogonality doc's "ship as needed" disposition. This
package currently ships only the typed-element lattice above.

## Topics

### Capability protocols

- ``Span/Protocol``
- ``Span/Borrowed/Protocol``
- ``Span/Mutable/Protocol``
