//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import CoreFoundation

class BinaryReader {
  let buffer: Uint8List
  var position: Int = 0

  var length: Int { buffer.count }

  init(_ buffer: Uint8List) {
    self.buffer = buffer
  }

  /// 从当前流中读取下一个字节，并使流的当前位置提升 1 个字节
  /// 返回下一个字节(0-255)
  func read() -> UInt8 {
    guard position < buffer.count else { return 0 }
    let byte = buffer[position]
    position += 1
    return byte
  }

  /// 从当前流中读取指定长度的字节整数，并使流的当前位置提升指定长度。
  /// length 指定长度
  /// len=1为int8,2为int16,4为int32,8为int64。dart中统一为int类型
  /// 返回整数
  func readInt(_ length: Int) throws -> Int {
    guard position + length <= buffer.count else {
      throw BinaryReaderError.outOfBounds
    }

    let bytes = Uint8List(buffer[position ..< (position + length)])
    position += length

    var result = 0

    switch length {
    case 1:
      result = Int(bytes[0])

    case 2:
      let value = bytes.withUnsafeBytes { $0.load(as: Int16.self) }
      result = Int(Int16(bigEndian: value))

    case 4:
      let value = bytes.withUnsafeBytes { $0.load(as: Int32.self) }
      result = Int(Int32(bigEndian: value))

    case 8:
      let value = bytes.withUnsafeBytes { $0.load(as: Int64.self) }
      result = Int(Int64(bigEndian: value))

    default:
      throw BinaryReaderError.invalidLength
    }

    return result
  }

  /// 从当前流中读取指定长度的字节数组，并使流的当前位置提升指定长度。
  /// [len] 指定长度
  /// 返回字节数组
  func readBytes(_ length: Int) -> Uint8List {
    guard position + length <= buffer.count else {
      fatalError("Buffer overrun: not enough bytes to read")
    }
    let result = Array(buffer[position ..< (position + length)])
    position += length
    return result
  }

  /// 从当前流中读取指定长度的字节浮点数，并使流的当前位置提升指定长度。
  /// [len] 指定长度
  /// len=4为float,8为double。dart中统一为double类型
  /// 返回浮点数
  func readFloat(_ length: Int) -> Double {
    guard position + length <= buffer.count else {
      fatalError("Buffer overrun: not enough bytes to read")
    }
    let bytes = Array(buffer[position ..< (position + length)])
    defer { position += length } // 确保位置更新

    switch length {
    case 4:
      let bits = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
      let swapped = CFSwapInt32BigToHost(bits)
      return Double(Float(bitPattern: swapped))

    case 8:
      let bits = bytes.withUnsafeBytes { $0.load(as: UInt64.self) }
      let swapped = CFSwapInt64BigToHost(bits)
      return Double(bitPattern: swapped)

    default:
      fatalError("Invalid length: \(length). Must be 4 or 8 bytes.")
    }
  }
}
