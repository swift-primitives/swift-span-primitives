import Span_Primitives_Test_Support
import Testing

@Suite struct `Raw Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Raw Tests`.Unit {
    @Test
    func `wraps a buffer and vends spans via the Span capability`() {
        let n = 16
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: n, alignment: 8)
        defer { unsafe buffer.deallocate() }
        let raw: Span.Raw.Mutable = unsafe .init(buffer)
        #expect(!raw.isEmpty)
        let spanCount = raw.span.count
        #expect(spanCount == n)
        let immutableCount = raw.immutable.span.count
        #expect(immutableCount == n)
    }
}

extension `Raw Tests`.`Edge Case` {
    @Test
    func `empty raw span is empty with a non-null sentinel`() {
        let raw: Span.Raw = .init()
        #expect(raw.isEmpty)
        let spanEmpty = raw.span.isEmpty
        #expect(spanEmpty)
        #expect(unsafe raw.base.nonNull.baseAddress != nil)
        #expect(unsafe raw.base.nullable.baseAddress == nil)
    }
}
