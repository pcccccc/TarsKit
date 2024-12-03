//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

// MARK: - UniAttributeError

enum UniAttributeError: Error {
  case nullKey
  case nullValue
  case invalidTup2Format
  case unimplemented
  case objectIsNull
  case invalidMapData
  case typeMismatch(expected: String, actual: String)
}

// MARK: - UniAttribute

public class UniAttribute: TarsStruct {
  var version = Constants.packetTypeTup
  var encodeName = "UTF-8"

  var newData: [String: Uint8List] = [:]
  var oldData: [String: [String: Uint8List]] = [:]
  var cachedData: [String: Any] = [:]

  private let inputStream = TarsInputStream()

  var isEmpty: Bool {
    version == Constants.packetTypeTup3 ? newData.isEmpty : oldData.isEmpty
  }

  var length: Int {
    version == Constants.packetTypeTup3 ? newData.count : oldData.count
  }

  public func writeTo(_ outputs: TarsOutputStream) throws {
    if version == Constants.packetTypeTup3 {
      try outputs.write(newData, tag: 0)
    } else {
      try outputs.write(oldData, tag: 0)
    }
  }

  public func readFrom(_ inputs: TarsInputStream) throws {
    if version == Constants.packetTypeTup3 {
      newData = ["": Uint8List([0x0])]
      newData = try inputs.readMap(newData, tag: 0, required: false)
    } else {
      oldData = try inputs.readMapMap(oldData, tag: 0, required: false)
    }
  }

  public func deepCopy() -> Self {
    fatalError("Unimplemented")
  }

  public func displayAsString(_ sb: inout String, level: Int) {
    fatalError("Unimplemented")
  }

  public func get<T>(_ name: String, defaultValue: T) -> T {
    do {
      if version == Constants.packetTypeTup3 {
        return try getByClass(name, proxy: defaultValue)
      } else {
        return try get2(name, proxy: defaultValue)
      }
    } catch {
      return defaultValue
    }
  }

  func clearCacheData() {
    cachedData.removeAll()
  }

  func containsKey(_ key: String) -> Bool {
    version == Constants.packetTypeTup3 ? newData.keys.contains(key) : oldData.keys.contains(key)
  }

  func put<T>(_ name: String, _ value: T) throws {
    guard !name.isEmpty else { throw UniAttributeError.nullKey }

    let outputStream = TarsOutputStream()
    outputStream.setServerEncoding(encodeName)
    try outputStream.write(value, tag: 0)
    let buffer = outputStream.toUint8List()

    if version == Constants.packetTypeTup3 {
      cachedData.removeValue(forKey: name)
      newData[name] = buffer
    } else {
      var listType: [String] = []
      try checkObjectType(&listType, value)
      let className = BasicClassTypeUtil.transTypeList(listType)

      cachedData.removeValue(forKey: name)
      oldData[name] = [className: buffer]
    }
  }

  func encode() throws -> Uint8List {
    let outputStream = TarsOutputStream()
    outputStream.setServerEncoding(encodeName)

    if version == Constants.packetTypeTup3 {
      try outputStream.write(newData, tag: 0)
    } else {
      try outputStream.write(oldData, tag: 0)
    }

    return outputStream.toUint8List()
  }

  func decode(_ buffer: Uint8List, index: Int = 0) throws {
    do {
      inputStream.wrap(buffer, pos: index)
      inputStream.setServerEncoding(encodeName)
      version = Constants.packetTypeTup
      oldData = try inputStream.readMapMap(oldData, tag: 0, required: false)
    } catch {
      version = Constants.packetTypeTup3
      inputStream.wrap(buffer, pos: index)
      inputStream.setServerEncoding(encodeName)
      newData = try inputStream.readMap(["": Uint8List([0x0])], tag: 0, required: false)
    }
  }

  private func checkObjectType(_ listType: inout [String], _ object: Any) throws {
    if let array = object as? [Any] {
      listType.append("list")
      if let first = array.first {
        try checkObjectType(&listType, first)
      } else {
        listType.append("?")
      }
    } else if let dict = object as? [AnyHashable: Any] {
      listType.append("map")
      if let (key, value) = dict.first {
        listType.append(BasicClassTypeUtil.toUniType(
          type: String(describing: type(of: key)),
          obj: key))
        try checkObjectType(&listType, value)
      } else {
        listType.append("?")
        listType.append("?")
      }
    } else {
      listType.append(BasicClassTypeUtil.toUniType(
        type: String(describing: type(of: object)),
        obj: object))
    }
  }

  private func getByClass<T>(_ name: String, proxy: T) throws -> T {
    if version == Constants.packetTypeTup3 {
      if let cached = cachedData[name] as? T { return cached }
      guard let data = newData[name] else { return proxy }
      let decoded = try decodeData(data, proxy: proxy)
      guard let result = decoded as? T else {
        throw UniAttributeError.typeMismatch(
          expected: String(describing: T.self),
          actual: String(describing: type(of: decoded)))
      }
      saveDataCache(name: name, value: result)
      return result
    } else {
      return try get2(name, proxy: proxy)
    }
  }

  private func get2<T>(_ name: String, proxy: T? = nil) throws -> T {
    guard version != Constants.packetTypeTup3 else {
      throw UniAttributeError.invalidTup2Format
    }

    if let cached = cachedData[name] as? T {
      return cached
    }

    guard
      let data = oldData[name],
      let className = data.keys.first,
      let buffer = data[className]
    else {
      throw UniAttributeError.invalidMapData
    }

    let decoded = try decodeData(buffer, proxy: proxy)
    guard let result = decoded as? T else {
      throw UniAttributeError.typeMismatch(
        expected: String(describing: T.self),
        actual: String(describing: type(of: decoded)))
    }
    return result
  }

  private func decodeData(_ data: Uint8List, proxy: Any?) throws -> Any {
    inputStream.wrap(data)
    inputStream.setServerEncoding(encodeName)
    guard var p = proxy else { throw UniAttributeError.nullValue }
    return try inputStream.read(&p, tag: 0, required: true)
  }

  private func saveDataCache(name: String, value: Any) {
    cachedData[name] = value
  }
}
