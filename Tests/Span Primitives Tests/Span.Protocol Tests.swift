import Index_Primitives
import Span_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure
//
// Tests mirror the source domain model per [INST-TEST-013]: the test struct
// is a subdomain of the `Span` namespace, with the four canonical sub-suites
// per [TEST-005].

@Suite struct SpanTests {}

extension SpanTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite struct Performance {}
}

// MARK: - Fixtures
//
// Owned conformers backed by stdlib contiguous storage. Declared as members
// of the test subdomain ([INST-TEST-013]) — they reference the source-domain
// protocols directly, no parallel vocabulary.

extension SpanTests {
    /// An owned region of `Int` that vends a read span by borrowing `self`.
    ///
    /// Conforms to ``Span/Protocol`` (the owned leg).
    struct OwnedInts: Span.`Protocol` {
        typealias Element = Int
        var storage: [Int]
        init(_ storage: [Int]) { self.storage = storage }
        var span: Swift.Span<Int> {
            @_lifetime(borrow self) get { storage.span }
        }
    }

    /// An owned region of `Int` that vends both a read span and a mutable
    /// span.
    ///
    /// Conforms to ``Span/Mutable/Protocol`` (the mutable refinement).
    struct MutableInts: Span.Mutable.`Protocol` {
        typealias Element = Int
        var storage: [Int]
        init(_ storage: [Int]) { self.storage = storage }
        var span: Swift.Span<Int> {
            @_lifetime(borrow self) get { storage.span }
        }
        var mutableSpan: Swift.MutableSpan<Int> {
            mutating get { storage.mutableSpan }
        }
        // Pre-existing fixture gap (growth-genericity #12a added this requirement to
        // Span.Mutable.Protocol without updating this fixture). Fixed here so the suite
        // compiles; this fixture is exercised only with the full extent.
        @_lifetime(&self)
        mutating func mutableSpan(count: Index<Int>.Count) -> Swift.MutableSpan<Int> {
            storage.mutableSpan
        }
    }

    /// A move-only element.
    struct Token: ~Copyable {
        let id: Int
        init(_ id: Int) { self.id = id }
    }

    /// A `~Copyable` owned region of `~Copyable` elements, vending a read span.
    ///
    /// Conforms to ``Span/Protocol`` with a `~Copyable` `Element`.
    struct OwnedTokens: ~Copyable, Span.`Protocol` {
        typealias Element = Token
        var storage: InlineArray<3, Token>
        init(_ storage: consuming InlineArray<3, Token>) { self.storage = storage }
        var span: Swift.Span<Token> {
            @_lifetime(borrow self) get { storage.span }
        }
    }
}

// MARK: - Unit

extension SpanTests.Unit {
    // (a) An owned struct conforms to Span.`Protocol` and vends a read span.
    @Test
    func `owned struct conforms to Span Protocol and vends span`() {
        let region = SpanTests.OwnedInts([10, 20, 30])
        let span = region.span
        #expect(span.count == 3)
        #expect(span[0] == 10)
        #expect(span[2] == 30)
    }

    // (b) An owned struct conforms to Span.Mutable.`Protocol` and vends a
    //     mutable span; mutation through it is observable on the read span.
    @Test
    func `owned struct conforms to Span Mutable Protocol and vends mutableSpan`() {
        var region = SpanTests.MutableInts([1, 2, 3])
        do {
            var m = region.mutableSpan
            #expect(m.count == 3)
            m[0] = 99
        }
        let span = region.span
        #expect(span[0] == 99)
        #expect(span[1] == 2)
    }

    // (c) The linchpin: a bare Swift.Span<UInt8> satisfies the unified
    //     Span.`Protocol` and round-trips its bytes through `.span`.
    @Test
    func `bare Swift Span of UInt8 satisfies Span Protocol and round-trips bytes`() {
        let bytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        let span: Swift.Span<UInt8> = bytes.span
        // `.span` is the Span.`Protocol` requirement — identity.
        let vended = span.span
        #expect(vended.count == 4)
        #expect(vended[0] == 0xDE)
        #expect(vended[1] == 0xAD)
        #expect(vended[2] == 0xBE)
        #expect(vended[3] == 0xEF)
    }

    // (d) A ~Copyable-element owned region conforms to Span.`Protocol`.
    @Test
    func `~Copyable element owned region conforms to Span Protocol`() {
        let region = SpanTests.OwnedTokens(InlineArray<3, SpanTests.Token> { SpanTests.Token($0 + 1) })
        let span = region.span
        #expect(span.count == 3)
        #expect(span[0].id == 1)
        #expect(span[2].id == 3)
    }
}

// MARK: - Edge Case

extension SpanTests.`Edge Case` {
    // The linchpin over an empty span: identity still holds, count is zero.
    @Test
    func `empty Swift Span satisfies Span Protocol with zero count`() {
        let empty: [UInt8] = []
        let span: Swift.Span<UInt8> = empty.span
        let vended = span.span
        // Extract to plain values: `#expect`'s property-access path requires
        // its receiver to be Escapable, and Swift.Span is ~Escapable.
        let count = vended.count
        let isEmpty = vended.isEmpty
        #expect(count == 0)
        #expect(isEmpty)
    }

    // An owned region with a single element vends a length-1 span.
    @Test
    func `single-element owned region vends length-one span`() {
        let region = SpanTests.OwnedInts([42])
        let span = region.span
        #expect(span.count == 1)
        #expect(span[0] == 42)
    }
}

// MARK: - Integration
//
// Generic code parameterized on the capability protocols, exercised against
// the concrete conformers — proving the protocols are usable as generic
// constraints, not just as conformances.

extension SpanTests.Integration {
    /// Sums the elements of any owned `Int` span capability.
    ///
    /// `Element` is constrained via a `where` clause (the protocols declare
    /// `associatedtype Element`, not a primary associated type), and `R` is
    /// allowed `~Copyable` so the owned capability composes with move-only
    /// conformers.
    static func sum<R: Span.`Protocol` & ~Copyable>(_ region: borrowing R) -> Int
    where R.Element == Int {
        let span = region.span
        var total = 0
        for i in 0..<span.count { total += span[i] }
        return total
    }

    /// Reads the first byte of any byte-span capability, including a bare
    /// `Swift.Span<UInt8>`.
    ///
    /// The constraint MUST restate `~Copyable & ~Escapable` — a bare
    /// `some Span.`Protocol`` would implicitly require `Escapable` `Self` and
    /// reject a bare `Swift.Span` (which is `~Escapable`). This is the
    /// conformer-guidance finding documented on ``Span/Protocol``.
    static func firstByte<R: Span.`Protocol` & ~Copyable & ~Escapable>(
        _ region: borrowing R
    ) -> UInt8? where R.Element == UInt8 {
        let span = region.span
        return span.isEmpty ? nil : span[0]
    }

    @Test
    func `generic over Span Protocol sums an owned region`() {
        let region = SpanTests.OwnedInts([5, 7, 11])
        #expect(Self.sum(region) == 23)
    }

    @Test
    func `generic over Span Protocol sums a mutable region after edit`() {
        var region = SpanTests.MutableInts([1, 1, 1])
        do {
            var m = region.mutableSpan
            m[2] = 8
        }
        // MutableInts is a Span.Mutable.`Protocol`, hence a Span.`Protocol`.
        #expect(Self.sum(region) == 10)
    }

    @Test
    func `generic over suppressed Span Protocol reads first byte of a bare span`() {
        let bytes: [UInt8] = [0x7F, 0x00]
        let span: Swift.Span<UInt8> = bytes.span
        #expect(Self.firstByte(span) == 0x7F)
    }
}

// MARK: - Performance
//
// No timing assertions in the toolchain test layer (performance work lives in
// nested swift-testing benchmark packages per the `benchmark` skill). The
// suite is declared for the [TEST-005] canonical-category set.

extension SpanTests.Performance {}
