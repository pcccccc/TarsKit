import Foundation

// MARK: - TarsOutputStream

//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

public class TarsOutputStream {
  var writer: BinaryWriter
  var sServerEncoding = "UTF-8"

  init(buffer: Uint8List = []) {
    self.writer = BinaryWriter(buffer: buffer)
  }

  public func write(_ value: Any, tag: Int) throws {
    switch value {
    case let v as Int:
      try writeInt(v, tag: tag)
    case let v as Int32:
      try writeInt(Int(v), tag: tag)
    case let v as Int64:
      try writeInt(Int(v), tag: tag)
    case let v as Double:
      try writeDouble(v, tag: tag)
    case let v as Float:
      try writeDouble(Double(v), tag: tag)
    case let v as Bool:
      try writeBool(v, tag: tag)
    case let v as Uint8List:
      try writeUint8List(v, tag: tag)
    case let v as String:
      try writeString(v, tag: tag)
    case let v as [Any]:
      try writeList(v, tag: tag)
    case let v as [AnyHashable: Any]:
      try writeMap(v, tag: tag)
    case let v as any TarsStruct:
      try writeTarsStruct(v, tag: tag)
    default:
      throw TarsStreamError.invalidType(String(describing: type(of: value)))
    }
  }

  func writeHead(_ type: TarsStructType, tag: Int) throws {
    if tag < 15 {
      let b = (tag << 4) | type.rawValue
      try writer.writeInt(b, length: 1)
    } else if tag < 256 {
      let b = (15 << 4) | type.rawValue
      try writer.writeInt(b, length: 1)
      try writer.writeInt(tag, length: 1)
    } else {
      throw TarsEncodeException("tag is too large: \(tag)")
    }
  }

  /// 写入bool
  /// 对应Tars类型：int1
  func writeBool(_ b: Bool, tag: Int) throws {
    try writeByte(b ? 1 : 0, tag: tag)
  }

  /// 写入字节
  /// 对应Tars类型：int1
  func writeByte(_ b: Int, tag: Int) throws {
    if b == 0 {
      try writeHead(.zeroTag, tag: tag)
    } else {
      try writeHead(.byte, tag: tag)
      try writer.writeInt(b, length: 1)
    }
  }

  /// 写入整数型
  /// 对应Tars类型：int1、int2、int4、int8
  func writeInt(_ n: Int, tag: Int) throws {
    if n >= -128, n <= 127 {
      try writeByte(n, tag: tag)
    } else if n >= -32768, n <= 32767 {
      try writeHead(.short, tag: tag)
      try writer.writeInt(n, length: 2)
    } else if n >= -2_147_483_648, n <= 2_147_483_647 {
      try writeHead(.int, tag: tag)
      try writer.writeInt(n, length: 4)
    } else if n >= -9_223_372_036_854_775_808, n <= 9_223_372_036_854_775_807 {
      try writeHead(.long, tag: tag)
      try writer.writeInt(n, length: 8)
    }
  }

  /// 写入浮点数
  /// 对应Tars类型：float
  func writeFloat(_ n: Float, tag: Int) throws {
    try writeHead(.float, tag: tag)
    try writer.writeDouble(Double(n), length: 4)
  }

  /// 写入双精度浮点数(Double)
  /// 对应Tars类型：double
  func writeDouble(_ n: Double, tag: Int) throws {
    try writeHead(.double, tag: tag)
    try writer.writeDouble(n, length: 8)
  }

  /// 写入字符串
  /// 对应Tars类型：string1、string4
  func writeString(_ s: String, tag: Int) throws {
    let bytes = Array(s.utf8)
    if bytes.isEmpty {
      try writeHead(.string1, tag: tag)
      try writer.writeInt(0, length: 1)
    }
    if bytes.count > 255 {
      try writeHead(.string4, tag: tag)
      try writer.writeInt(bytes.count, length: 4)
      writer.writeBytes(bytes)
    } else {
      try writeHead(.string1, tag: tag)
      try writer.writeInt(bytes.count, length: 1)
      writer.writeBytes(bytes)
    }
  }

  /// 写入byte[]
  /// 对应Tars类型：SimpleList
  func writeUint8List(_ ls: Uint8List, tag: Int) throws {
    try writeHead(.simpleList, tag: tag)
    try writeHead(.byte, tag: 0)
    try writeInt(ls.count, tag: 0)
    writer.writeBytes(ls)
  }

  /// 写入Map
  /// 对应Tars类型：Map
  func writeMap(_ map: [AnyHashable: Any], tag: Int) throws {
    try writeHead(.map, tag: tag)
    try writeInt(map.count, tag: 0)
    for (key, value) in map {
      try write(key, tag: 0)
      try write(value, tag: 1)
    }
  }

  /// 写入列表
  /// 对应Tars类型：List
  func writeList(_ ls: [Any], tag: Int) throws {
    try writeHead(.list, tag: tag)
    try writeInt(ls.count, tag: 0)
    for item in ls {
      try write(item, tag: 0)
    }
  }

  /// 写入自定义结构
  /// 对应Tars类型：TarsStruct
  func writeTarsStruct(_ value: any TarsStruct, tag: Int) throws {
    try writeHead(.structBegin, tag: tag)
    try value.writeTo(self)
    try writeHead(.structEnd, tag: 0)
  }

  func toUint8List() -> Uint8List {
    writer.buffer
  }

  func setServerEncoding(_ encoding: String) {
    sServerEncoding = encoding
  }
}
