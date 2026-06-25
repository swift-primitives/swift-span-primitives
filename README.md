# Span Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-span-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-span-primitives/actions/workflows/ci.yml)

`Span` — the span-vending **capability** domain. It answers one question: *what can vend a contiguous view of its elements?* A type conforms to `Span.Protocol` to expose a `Swift.Span<Element>` (or, via `Span.Mutable.Protocol`, a `Swift.MutableSpan`) over its storage — and generic algorithms then range over *any* such type.

The capability is deliberately **decoupled from any single domain**. A memory region vends a span; a contiguous `Storage` vends a span; a binary buffer vends a span; a bare `Swift.Span` vends itself. Naming the protocol after any one of those domains (`Storage.Contiguous.Borrowed.Protocol`, say) would couple the others to it — so the protocol lives here, domain-neutral, and each domain conforms without depending on the rest. `Span.Raw` carries the same capability for untyped, byte-addressed spans.

---

## Key Features

- **One capability, every domain** — memory regions, storages, buffers, and byte streams all expose elements through the same `Span.Protocol` surface, so a span algorithm is written once.
- **Borrowed, non-escaping views** — `Span.Protocol` is `~Escapable`; conformers vend a `Swift.Span` that borrows their storage without copying or escaping it (SE-0447 spans).
- **Typed and raw** — `Span.Protocol` for `Swift.Span<Element>`; `Span.Mutable.Protocol` for `Swift.MutableSpan`; `Span.Raw` for untyped byte spans.
- **`~Copyable` elements** — the element associated type is `~Copyable`, so move-only elements are viewable in place.
- **`Span` *is* the stdlib type** — `Span<Element>` is `Swift.Span<Element>` and `Span.Mutable<Element>` is `Swift.MutableSpan<Element>` (unbound typealiases). The package re-exports the standard-library span family under the `Span` name and surfaces the capability as `Span.Protocol` / `Span.Mutable.Protocol`, so consumers write `Span<Byte>` and `Span.Protocol` rather than fully-qualifying `Swift.Span`.

---

## Quick Start

```swift
import Span_Protocol_Primitives

// Range over any span-vending type — memory regions, storages, buffers.
func isEmpty<S: Span.`Protocol` & ~Copyable & ~Escapable>(_ source: borrowing S) -> Bool {
    source.span.isEmpty
}
```

A type joins the domain by vending its span:

```swift
extension MyStorage: Span.`Protocol` {
    public var span: Swift.Span<Element> { /* borrow the backing buffer */ }
}
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Span Primitives", package: "swift-span-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Span Primitives` | Umbrella — re-exports the `Span` aliases and the capability protocols | Most consumers |
| `Span Primitive` | the `Span` / `Span.Mutable` aliases to `Swift.Span` / `Swift.MutableSpan` | Naming the span types directly |
| `Span Protocol Primitives` | `Span.Protocol` / `Span.Mutable.Protocol` — the vend-a-`Swift.Span` capability | Conforming a type, or writing code generic over span-vending |
| `Span Raw Primitives` | `Span.Raw` — untyped, byte-addressed spans | Raw / byte-span work |
| `Span Primitives Test Support` | Re-exports for downstream test targets | Test target only |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-byte-primitives`](https://github.com/swift-primitives/swift-byte-primitives) — `Byte`, the element of `Span.Raw`'s untyped spans.
- [`swift-index-primitives`](https://github.com/swift-primitives/swift-index-primitives) — `Index<Element>`, the typed positions into a span.
- [`swift-storage-primitives`](https://github.com/swift-primitives/swift-storage-primitives) — `Storage`, a contiguous substrate that vends its span via this capability (`Storage.Contiguous` is the owned typed region).

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
