import Index_Primitives
import Span_Primitives_Test_Support
import Testing

@Suite struct `Span Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Span Tests` {

    struct Owned: Span.`Protocol` {
        var storage: [Int]
        init(_ storage: [Int]) { self.storage = storage }
    }

    struct Mutable: Span.Mutable.`Protocol` {
        var storage: [Int]
        init(_ storage: [Int]) { self.storage = storage }
    }

    struct Token: ~Copyable {
        let id: Int
        init(_ id: Int) { self.id = id }
    }

    struct Tokens: ~Copyable, Span.`Protocol` {
        var storage: InlineArray<3, Token>
        init(_ storage: consuming InlineArray<3, Token>) { self.storage = storage }
    }
}

extension `Span Tests`.Owned {
    typealias Element = Int

    var span: Swift.Span<Int> {
        @_lifetime(borrow self) get { storage.span }
    }
}

extension `Span Tests`.Mutable {
    typealias Element = Int

    var span: Swift.Span<Int> {
        @_lifetime(borrow self) get { storage.span }
    }
    var mutableSpan: Swift.MutableSpan<Int> {
        mutating get { storage.mutableSpan }
    }

    @_lifetime(&self)
    mutating func mutableSpan(count: Index<Int>.Count) -> Swift.MutableSpan<Int> {
        storage.mutableSpan
    }
}

extension `Span Tests`.Tokens {
    typealias Element = `Span Tests`.Token

    var span: Swift.Span<`Span Tests`.Token> {
        @_lifetime(borrow self) get { storage.span }
    }
}

extension `Span Tests`.Unit {

    @Test
    func `owned struct conforms to Span Protocol and vends span`() {
        let region = `Span Tests`.Owned([10, 20, 30])
        let span = region.span
        #expect(span.count == 3)
        #expect(span[0] == 10)
        #expect(span[2] == 30)
    }

    @Test
    func `owned struct conforms to Span Mutable Protocol and vends mutableSpan`() {
        var region = `Span Tests`.Mutable([1, 2, 3])
        do {
            var m = region.mutableSpan
            #expect(m.count == 3)
            m[0] = 99
        }
        let span = region.span
        #expect(span[0] == 99)
        #expect(span[1] == 2)
    }

    @Test
    func `bare Swift Span of UInt8 satisfies Span Protocol and round-trips bytes`() {
        let bytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        let span: Swift.Span<UInt8> = bytes.span

        let vended = span.span
        #expect(vended.count == 4)
        #expect(vended[0] == 0xDE)
        #expect(vended[1] == 0xAD)
        #expect(vended[2] == 0xBE)
        #expect(vended[3] == 0xEF)
    }

    @Test
    func `~Copyable element owned region conforms to Span Protocol`() {
        let region = `Span Tests`.Tokens(
            InlineArray<3, `Span Tests`.Token> { `Span Tests`.Token($0 + 1) }
        )
        let span = region.span
        #expect(span.count == 3)
        #expect(span[0].id == 1)
        #expect(span[2].id == 3)
    }
}

extension `Span Tests`.`Edge Case` {

    @Test
    func `empty Swift Span satisfies Span Protocol with zero count`() {
        let empty: [UInt8] = []
        let span: Swift.Span<UInt8> = empty.span
        let vended = span.span

        let count = vended.count
        let isEmpty = vended.isEmpty
        #expect(count == 0)
        #expect(isEmpty)
    }

    @Test
    func `single-element owned region vends length-one span`() {
        let region = `Span Tests`.Owned([42])
        let span = region.span
        #expect(span.count == 1)
        #expect(span[0] == 42)
    }
}

extension `Span Tests`.Integration {

    static func sum<R: Span.`Protocol` & ~Copyable>(_ region: borrowing R) -> Int
    where R.Element == Int {
        let span = region.span
        var total = 0

        for i in 0..<span.count { total += span[i] }
        return total
    }

    static func firstByte<R: Span.`Protocol` & ~Copyable & ~Escapable>(
        _ region: borrowing R
    ) -> UInt8? where R.Element == UInt8 {
        let span = region.span
        return span.isEmpty ? nil : span[0]
    }

    @Test
    func `generic over Span Protocol sums an owned region`() {
        let region = `Span Tests`.Owned([5, 7, 11])
        #expect(Self.sum(region) == 23)
    }

    @Test
    func `generic over Span Protocol sums a mutable region after edit`() {
        var region = `Span Tests`.Mutable([1, 1, 1])
        do {
            var m = region.mutableSpan
            m[2] = 8
        }

        #expect(Self.sum(region) == 10)
    }

    @Test
    func `generic over suppressed Span Protocol reads first byte of a bare span`() {
        let bytes: [UInt8] = [0x7F, 0x00]
        let span: Swift.Span<UInt8> = bytes.span
        #expect(Self.firstByte(span) == 0x7F)
    }
}

extension `Span Tests`.Performance {}
