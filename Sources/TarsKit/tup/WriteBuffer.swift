//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

// MARK: - Endian

enum Endian {
  case littleEndian
  case bigEndian

  static var host: Endian {
    #if _endian(little)
    return .littleEndian
    #else
    return .bigEndian
    #endif
  }
}

// MARK: - WriteBuffer

/// 用于增量构建 Data 实例的只写缓冲区
///
/// WriteBuffer 实例只能使用一次。尝试重用将导致抛出 StateError。
class WriteBuffer {
  private static let zeroBuffer = Uint8List(repeating: 0, count: 8)

  let eightBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)

  private var buffer: Uint8List
  private var currentSize = 0
  private var isDone = false

  init(startCapacity: Int = 8) {
    precondition(startCapacity > 0)
    self.buffer = Uint8List(repeating: 0, count: startCapacity)
  }

  deinit {
    eightBytes.deallocate()
  }

  func putUint8(_ value: UInt8) {
    precondition(!isDone)
    add(value)
  }

  func putUint16(_ value: UInt16, endian: Endian = .bigEndian) {
    precondition(!isDone)
    let bytes =
      switch endian {
      case .littleEndian: value.littleEndian
      case .bigEndian: value.bigEndian
      }
    withUnsafeBytes(of: bytes) { append(Array($0)) }
  }

  func putUint32(_ value: UInt32, endian: Endian = .bigEndian) {
    precondition(!isDone)
    let bytes =
      switch endian {
      case .littleEndian: value.littleEndian
      case .bigEndian: value.bigEndian
      }
    withUnsafeBytes(of: bytes) { append(Array($0)) }
  }

  func putInt32(_ value: Int32, endian: Endian = .bigEndian) {
    precondition(!isDone)
    let bytes =
      switch endian {
      case .littleEndian: value.littleEndian
      case .bigEndian: value.bigEndian
      }
    withUnsafeBytes(of: bytes) { append(Array($0)) }
  }

  func putInt64(_ value: Int64, endian: Endian = .bigEndian) {
    precondition(!isDone)
    let bytes =
      switch endian {
      case .littleEndian: value.littleEndian
      case .bigEndian: value.bigEndian
      }
    withUnsafeBytes(of: bytes) { append(Array($0)) }
  }

  func putFloat64(_ value: Double, endian: Endian = .bigEndian) {
    precondition(!isDone)
    alignTo(8)
    var bytes = value.bitPattern
    switch endian {
    case .littleEndian: bytes = bytes.littleEndian
    case .bigEndian: bytes = bytes.bigEndian
    }
    withUnsafeBytes(of: bytes) { append(Array($0)) }
  }

  func putUint8List(_ data: Uint8List) {
    precondition(!isDone)
    append(data)
  }

  func done() -> Data {
    precondition(!isDone, "done() must not be called more than once")
    isDone = true
    return Data(buffer[0 ..< currentSize])
  }

  private func add(_ byte: UInt8) {
    if currentSize == buffer.count {
      resize()
    }
    buffer[currentSize] = byte
    currentSize += 1
  }

  private func append(_ other: Uint8List) {
    let newSize = currentSize + other.count
    if newSize >= buffer.count {
      resize(requiredLength: newSize)
    }
    buffer.replaceSubrange(currentSize ..< newSize, with: other)
    currentSize += other.count
  }

  private func resize(requiredLength: Int? = nil) {
    let doubleLength = buffer.count * 2
    let newLength = max(requiredLength ?? 0, doubleLength)
    buffer.reserveCapacity(newLength)
    buffer += Uint8List(repeating: 0, count: newLength - buffer.count)
  }

  private func alignTo(_ alignment: Int) {
    let mod = currentSize % alignment
    if mod != 0 {
      append(Array(WriteBuffer.zeroBuffer[0 ..< (alignment - mod)]))
    }
  }
}
