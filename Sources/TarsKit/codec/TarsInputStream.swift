//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

// MARK: - HeadData

struct HeadData {
  var type: Int = 0
  var tag: Int = 0

  mutating func clear() {
    type = 0
    tag = 0
  }
}

// MARK: - TarsInputStream

public class TarsInputStream {
  var reader: BinaryReader!
  var serverEncoding = "UTF-8"

  init(_ data: [UInt8] = [], pos: Int = 0) {
    if !data.isEmpty {
      self.reader = BinaryReader(data)
      reader.position = pos
    }
  }

  static func readBinaryReaderHead(_ hd: inout HeadData, _ reader: BinaryReader) throws -> Int {
    guard reader.position < reader.length else {
      throw TarsStreamError.readToEnd
    }

    let b = reader.read()
    hd.type = Int(b & 15)
    hd.tag = Int((b & (15 << 4)) >> 4)

    if hd.tag == 15 {
      hd.tag = Int(reader.read())
      return 2
    }
    return 1
  }

  func wrap(_ data: Uint8List, pos: Int = 0) {
    reader = BinaryReader(data)
    reader.position = pos
  }

  @discardableResult
  func readHead(_ hd: inout HeadData) throws -> Int {
    try TarsInputStream.readBinaryReaderHead(&hd, reader)
  }

  func peakHead(_ hd: inout HeadData) throws -> Int {
    let curPos = reader.position
    let len = try readHead(&hd)
    reader.position = curPos
    return len
  }

  func skip(_ length: Int) {
    reader.position += length
  }

  func skipToTag(_ tag: Int) -> Bool {
    do {
      var hd = HeadData()
      while true {
        let len = try peakHead(&hd)
        if tag <= hd.tag || hd.type == TarsStructType.structEnd.rawValue {
          return tag == hd.tag
        }
        skip(len)
        try skipFieldWithType(hd.type)
      }
    } catch {
      print("Skip error: \(error)")
      return false
    }
  }

  /// 跳到当前结构的结束位置
  func skipToStructEnd() throws {
    var hd = HeadData()
    repeat {
      try readHead(&hd)
      try skipFieldWithType(hd.type)
    } while hd.type != TarsStructType.structEnd.rawValue
  }

  /// 跳过一个字段
  func skipField() throws {
    var hd = HeadData()
    try readHead(&hd)
    try skipFieldWithType(hd.type)
  }

  func skipFieldWithType(_ type: Int) throws {
    guard let t = TarsStructType(rawValue: type) else {
      throw TarsStreamError.invalidType("Invalid type: \(type)")
    }

    switch t {
    case .byte:
      skip(1)

    case .short:
      skip(2)

    case .int:
      skip(4)

    case .long:
      skip(8)

    case .float:
      skip(4)

    case .double:
      skip(8)

    case .string1:
      var len = Int(reader.read())
      if len < 0 { len += 256 }
      skip(len)

    case .string4:
      try skip(reader.readInt(4))

    case .map:
      let size = try readInt(0, required: true)
      for _ in 0 ..< (size * 2) {
        try skipField()
      }

    case .list:
      let size = try readInt(0, required: true)
      for _ in 0 ..< size {
        try skipField()
      }

    case .simpleList:
      var hd = HeadData()
      try readHead(&hd)
      guard hd.type == TarsStructType.byte.rawValue else {
        throw TarsStreamError.typeMismatch(
          expected: "TarsStruct simple list",
          actual: String(describing: TarsStructType(rawValue: hd.type)))
      }
      let size = try readInt(0, required: true)
      skip(size)

    case .structBegin:
      try skipToStructEnd()

    case .structEnd, .zeroTag:
      break
    }
  }
}

extension TarsInputStream {
  public func read<T>(_ data: inout T, tag: Int, required: Bool) throws -> T {
    let result: Any
    switch data {
    case is Int, is Int32, is Int64:
      result = try readInt(tag, required: required)
    case is Double, is Float:
      result = try readFloat(tag, required: required)
    case is Bool:
      result = try readBool(tag, required: required)
    case is Uint8List:
      result = try readBytes(tag, required: required)
    case is String:
      result = try readString(tag, required: required)
    case let array as [Any]:
      result = try readList(array, tag: tag, required: required)
    case let dict as [AnyHashable: Any]:
      result = try readMap(dict, tag: tag, required: required)
    case let structType as any TarsStruct:
      result = try readTarsStruct(structType, tag: tag, required: required)
    default:
      throw TarsStreamError.typeMismatch(expected: "Tars type", actual: String(describing: data))
    }
    guard let typedResult = result as? T else {
      throw TarsStreamError.typeMismatch(expected: String(describing: T.self), actual: String(describing: result))
    }

    return typedResult
  }

  /// 读取整数
  /// 对应Tars类型：int1、int2、int4、int8
  func readInt(_ tag: Int, required: Bool) throws -> Int {
    var result = 0
    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard let type = TarsStructType(rawValue: hd.type) else {
        throw TarsStreamError.invalidType("Invalid type")
      }

      switch type {
      case .zeroTag:
        result = 0
      case .byte:
        try result = reader.readInt(1)
      case .short:
        try result = reader.readInt(2)
      case .int:
        try result = reader.readInt(4)
      case .long:
        try result = reader.readInt(8)
      default:
        throw TarsStreamError.typeMismatch(expected: "TarsStruct int", actual: String(describing: type))
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return result
  }

  /// 读取bool
  /// 对应Tars类型：int1
  func readBool(_ tag: Int, required: Bool) throws -> Bool {
    try readInt(tag, required: required) != 0
  }

  /// 读取字符串
  /// 对应Tars类型：string1、string4
  func readString(_ tag: Int, required: Bool) throws -> String {
    var n = ""
    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard let type = TarsStructType(rawValue: hd.type) else {
        throw TarsStreamError.invalidType("Invalid type")
      }

      switch type {
      case .string1:
        n = try readString1()
      case .string4:
        n = try readString4()
      default:
        throw TarsStreamError.typeMismatch(expected: "TarsStruct string", actual: String(describing: type))
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return n
  }

  /// 读取浮点数
  /// 对应Tars类型：double、float
  func readFloat(_ tag: Int, required: Bool) throws -> Double {
    var n = 0.0
    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard let type = TarsStructType(rawValue: hd.type) else {
        throw TarsStreamError.invalidType("Invalid type")
      }

      switch type {
      case .zeroTag:
        n = 0.0
      case .float:
        n = reader.readFloat(4)
      case .double:
        n = reader.readFloat(8)
      default:
        throw TarsStreamError.typeMismatch(expected: "TarsStruct float", actual: String(describing: type))
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return n
  }

  /// 读取byte[]
  /// 对应Tars类型：SimpleList
  func readBytes(_ tag: Int, required: Bool) throws -> Uint8List {
    var bytes: Uint8List = []

    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard let type = TarsStructType(rawValue: hd.type) else {
        throw TarsStreamError.invalidType("Invalid type")
      }

      switch type {
      case .simpleList:
        var subHd = HeadData()
        try readHead(&subHd)
        guard subHd.type == TarsStructType.byte.rawValue else {
          throw TarsStreamError.typeMismatch(expected: "TarsStruct byte[]", actual: String(describing: subHd.type))
        }
        let size = try readInt(0, required: true)
        guard size >= 0 else {
          throw TarsStreamError.invalidSize("Invalid size: \(size)")
        }
        bytes = reader.readBytes(size)

      case .list:
        let size = try readInt(0, required: true)
        guard size >= 0 else {
          throw TarsStreamError.invalidSize("Invalid size: \(size)")
        }

        bytes = Uint8List(repeating: 0, count: size)
        for i in 0 ..< size {
          bytes[i] = try UInt8(readInt(0, required: true))
        }

      default:
        throw TarsStreamError.typeMismatch(expected: "TarsStruct list or simplelist", actual: String(describing: type))
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return bytes
  }

  /// 读取Map
  /// 需要指定键、值的类型
  /// 对应Tars类型：Map
  func readMap<K, V>(_ data: [K: V], tag: Int, required: Bool) throws -> [K: V] {
    guard let firstEntry = data.first else { return [:] }
    var k = firstEntry.key
    var v = firstEntry.value

    var map: [K: V] = [:]

    if skipToTag(tag) {
      var head = HeadData()
      try readHead(&head)

      guard
        let type = TarsStructType(rawValue: head.type),
        type == .map
      else {
        throw TarsStreamError.typeMismatch(expected: "TarsStruct map", actual: String(describing: head.type))
      }

      let size = try readInt(0, required: true)
      if size < 0 {
        throw TarsStreamError.invalidSize("Invalid size: \(size)")
      }

      for _ in 0 ..< size {
        if
          let mk = try? read(&k, tag: 0, required: true),
          let mv = try? read(&v, tag: 1, required: true)
        {
          map[mk] = mv
        }
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }

    return map
  }

  func readMapMap<K: Hashable, K2: Hashable, V2>(
    _ source: [K: [K2: V2]],
    tag: Int,
    required: Bool
  ) throws -> [K: [K2: V2]] {
    var map: [K: [K2: V2]] = [:]

    guard let firstEntry = source.first else {
      return [:]
    }
    var k = firstEntry.key
    let v = firstEntry.value

    if skipToTag(tag) {
      var head = HeadData()
      try readHead(&head)

      guard
        let type = TarsStructType(rawValue: head.type),
        type == .map
      else {
        throw TarsStreamError.typeMismatch(expected: "TarsStruct map", actual: String(describing: head.type))
      }

      let size = try readInt(0, required: true)
      guard size >= 0 else {
        throw TarsStreamError.invalidSize("Invalid size: \(size)")
      }

      for _ in 0 ..< size {
        if
          let mk = try? read(&k, tag: 0, required: true),
          let mv = try? readMap(v, tag: 1, required: true)
        {
          map[mk] = mv
        }
      }

    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }

    return map
  }

  /// 读取列表
  /// 对应Tars类型：List
  func readList<T>(_ array: [T], tag: Int, required: Bool) throws -> [T] {
    var result: [T] = []
    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard hd.type == TarsStructType.list.rawValue else {
        throw TarsStreamError.typeMismatch(expected: "TarsStruct list", actual: String(describing: hd.type))
      }

      let size = try readInt(0, required: true)
      guard size >= 0 else {
        throw TarsStreamError.invalidSize("Invalid size: \(size)")
      }

      for _ in 0 ..< size {
        guard var entry = array.first else {
          throw TarsStreamError.invalidType("Array element not found")
        }
        try result.append(read(&entry, tag: 0, required: true))
      }
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return result
  }

  /// 读取自定义结构
  /// 对应Tars类型：TarsStruct
  func readTarsStruct(_ value: any TarsStruct, tag: Int, required: Bool) throws -> any TarsStruct {
    if skipToTag(tag) {
      var hd = HeadData()
      try readHead(&hd)
      guard hd.type == TarsStructType.structBegin.rawValue else {
        throw TarsStreamError.typeMismatch(expected: "TarsStruct struct", actual: String(describing: hd.type))
      }

      let copy = value.deepCopy()
      try copy.readFrom(self)
      try skipToStructEnd()
      return copy
    } else if required {
      throw TarsStreamError.requiredFieldMissing
    }
    return value
  }

  func setServerEncoding(_ encoding: String) {
    serverEncoding = encoding
  }

  private func readString1() throws -> String {
    var len = 0
    len = try reader.readInt(1)
    if len < 0 { len += 256 }
    let bytes = reader.readBytes(len)
    guard let result = String(bytes: bytes, encoding: .utf8) else {
      throw TarsStreamError.invalidType("Invalid string")
    }
    return result
  }

  private func readString4() throws -> String {
    let len = try reader.readInt(4)
    if len > Constants.maxStringLength || len < 0 {
      throw TarsStreamError.invalidSize("String too long: \(len)")
    }
    let ss = reader.readBytes(len)
    guard let result = String(bytes: ss, encoding: .utf8) else {
      throw TarsStreamError.invalidType("Invalid string")
    }
    return result
  }
}
