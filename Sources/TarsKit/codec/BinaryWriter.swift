//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

class BinaryWriter {
  var buffer: Uint8List
  var position = 0

  var length: Int { buffer.count }

  init(buffer: Uint8List = []) {
    self.buffer = buffer
  }

  func writeBytes(_ list: Uint8List) {
    buffer.append(contentsOf: list)
    position += list.count
  }

  func writeInt(_ value: Int, length: Int) throws {
    var tempBuffer = [UInt8](repeating: 0, count: length)

    switch length {
    case 1:
      tempBuffer[0] = UInt8(value & 0xFF) // 取低 8 位
    case 2:
      let int16Value = Int16(value).bigEndian
      withUnsafeBytes(of: int16Value) { bytes in
        tempBuffer.replaceSubrange(0 ..< 2, with: bytes)
      }

    case 4:
      let int32Value = Int32(value).bigEndian
      withUnsafeBytes(of: int32Value) { bytes in
        tempBuffer.replaceSubrange(0 ..< 4, with: bytes)
      }

    case 8:
      let int64Value = Int64(value).bigEndian
      withUnsafeBytes(of: int64Value) { bytes in
        tempBuffer.replaceSubrange(0 ..< 8, with: bytes)
      }

    default:
      throw BinaryWriterError.invalidLength
    }

    buffer.append(contentsOf: tempBuffer)
    position += length
  }

  func writeDouble(_ value: Double, length: Int) throws {
    var tempBuffer = [UInt8](repeating: 0, count: length)

    switch length {
    case 4:
      let floatValue = Float(value).bitPattern.bigEndian
      withUnsafeBytes(of: floatValue) { bytes in
        tempBuffer.replaceSubrange(0 ..< 4, with: bytes)
      }

    case 8:
      let doubleValue = value.bitPattern.bigEndian
      withUnsafeBytes(of: doubleValue) { bytes in
        tempBuffer.replaceSubrange(0 ..< 8, with: bytes)
      }

    default:
      throw BinaryWriterError.invalidLength
    }

    buffer.append(contentsOf: tempBuffer)
    position += length
  }
}
