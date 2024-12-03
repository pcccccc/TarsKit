import Foundation

// 用于从 Data 实例顺序读取的只读缓冲区
//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

class ReadBuffer {
  private let data: Data
  private var position = 0

  var hasRemaining: Bool {
    position < data.count
  }

  init(_ data: Data) {
    self.data = data
  }

  func getUint8() -> UInt8 {
    defer { position += 1 }
    return data[position]
  }

  func getUint16(endian: Endian = .bigEndian) -> UInt16 {
    defer { position += 2 }
    let value = data[position ..< (position + 2)].withUnsafeBytes { $0.load(as: UInt16.self) }
    return endian == .littleEndian ? value.littleEndian : value.bigEndian
  }

  func getUint32(endian: Endian = .bigEndian) -> UInt32 {
    defer { position += 4 }
    let value = data[position ..< (position + 4)].withUnsafeBytes { $0.load(as: UInt32.self) }
    return endian == .littleEndian ? value.littleEndian : value.bigEndian
  }

  func getInt32(endian: Endian = .bigEndian) -> Int32 {
    defer { position += 4 }
    let value = data[position ..< (position + 4)].withUnsafeBytes { $0.load(as: Int32.self) }
    return endian == .littleEndian ? value.littleEndian : value.bigEndian
  }

  func getInt64(endian: Endian = .bigEndian) -> Int64 {
    defer { position += 8 }
    let value = data[position ..< (position + 8)].withUnsafeBytes { $0.load(as: Int64.self) }
    return endian == .littleEndian ? value.littleEndian : value.bigEndian
  }

  func getFloat64(endian: Endian = .bigEndian) -> Double {
    alignTo(8)
    defer { position += 8 }
    let value = data[position ..< (position + 8)].withUnsafeBytes { $0.load(as: Double.self) }
    let bits = value.bitPattern
    return Double(bitPattern: endian == .littleEndian ? bits.littleEndian : bits.bigEndian)
  }

  func getData(length: Int) -> Data {
    defer { position += length }
    return data[position ..< (position + length)]
  }

  private func alignTo(_ alignment: Int) {
    let mod = position % alignment
    if mod != 0 {
      position += alignment - mod
    }
  }
}
