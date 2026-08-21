import Byte_Primitives
import Byte_Protocol_Primitives
import Index_Primitives
import Span_Primitives_Test_Support
import Testing

extension __Span.Raw.Mutable {

    @Suite(.serialized) struct `Bounds Safety` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension __Span.Raw.Mutable.`Bounds Safety`.Unit {
    @Test
    func `mutableSpan(count:) at exactly the span's own count vends a fully usable span`() {
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe buffer.deallocate() }
        var raw: Span.Raw.Mutable = unsafe .init(buffer)
        var span = raw.mutableSpan(count: raw.count)
        #expect(span.count == 4)
        let first = span[0]
        let last = span[3]
        span[0] = last
        span[3] = first
        #expect(span[0] == last)
        #expect(span[3] == first)
    }

    @Test
    func `copy(from Span.Raw) with an exactly-sized source copies every byte`() {
        let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe dstBuffer.deallocate() }
        var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

        let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe srcBuffer.deallocate() }
        (0..<4).forEach { i in unsafe srcBuffer[i] = UInt8(i + 1) }
        let src: Span.Raw = unsafe .init(UnsafeRawBufferPointer(srcBuffer))

        dst.copy(from: src)
        #expect(unsafe Array(dstBuffer) == [1, 2, 3, 4])
    }

    @Test
    func
        `copy(from UnsafeRawBufferPointer) with a smaller source only overwrites the leading bytes`()
    {
        let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe dstBuffer.deallocate() }
        (0..<4).forEach { i in unsafe dstBuffer[i] = 0xff }
        var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

        let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 2, alignment: 1)
        defer { unsafe srcBuffer.deallocate() }
        unsafe srcBuffer[0] = 0x01
        unsafe srcBuffer[1] = 0x02

        unsafe dst.copy(from: UnsafeRawBufferPointer(srcBuffer))
        #expect(unsafe Array(dstBuffer) == [0x01, 0x02, 0xff, 0xff])
    }
}

extension __Span.Raw.Mutable.`Bounds Safety`.`Edge Case` {

    @Test
    func `mutableSpan(count:) traps when count exceeds the span's byte capacity`() async {
        await #expect(processExitsWith: .failure) {
            let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe buffer.deallocate() }
            var raw: Span.Raw.Mutable = unsafe .init(buffer)
            _ = raw.mutableSpan(count: Index<Byte>.Count(UInt(8)))
        }
    }

    @Test
    func
        `copy(from Span.Raw) traps under release when source has more bytes than the destination can hold`()
        async
    {
        guard !_isDebugAssertConfiguration() else { return }
        await #expect(processExitsWith: .failure) {
            let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe dstBuffer.deallocate() }
            var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

            let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 16, alignment: 1)
            defer { unsafe srcBuffer.deallocate() }
            let src: Span.Raw = unsafe .init(UnsafeRawBufferPointer(srcBuffer))

            dst.copy(from: src)
        }
    }

    @Test
    func
        `copy(from UnsafeRawBufferPointer) traps under release when source has more bytes than the destination can hold`()
        async
    {
        guard !_isDebugAssertConfiguration() else { return }
        await #expect(processExitsWith: .failure) {
            let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe dstBuffer.deallocate() }
            var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

            let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 16, alignment: 1)
            defer { unsafe srcBuffer.deallocate() }

            unsafe dst.copy(from: UnsafeRawBufferPointer(srcBuffer))
        }
    }
}
