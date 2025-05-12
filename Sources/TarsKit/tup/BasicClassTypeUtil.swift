//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

typealias BigInt = Int64
public typealias Uint8List = [UInt8]

// MARK: - BasicClassTypeUtil

class BasicClassTypeUtil {
  // MARK: - Type Conversion

  static func toUniType(type: String, obj: Any?) -> String {
    if type == "String" {
      return "string"
    }
    if type.contains("Array") || type.contains("List") {
      return "list"
    }
    if type.contains("Dictionary") || type.contains("Map") {
      return "map"
    }
    if type == "Bool" {
      return "bool"
    }

    // Int 类型检查
    if type == "Int" {
      if let obj = obj as? Int {
        if obj >= -32768, obj <= 32767 {
          return "short"
        }
        if obj >= 0, obj <= 65535 {
          return "ushort"
        }
        if obj >= -2_147_483_648, obj <= 2_147_483_647 {
          return "int32"
        }
        if obj >= 0, obj <= 4_294_967_295 {
          return "uint32"
        }
      }
      return "int32"
    }

    // BigInt 检查
    if type == String(describing: BigInt.self) {
      if let obj = obj as? BigInt {
        if obj >= -9_223_372_036_854_775_808, obj <= 9_223_372_036_854_775_807 {
          return "int64"
        }
        if obj >= 0 {
          return "uint64"
        }
      }
      return "int64"
    }

    if type == "Double" {
      return "double"
    }

    return type
  }

  static func transTypeList(_ listType: [String]) -> String {
    var types = listType.map { toUniType(type: $0, obj: nil) }
    types = Array(types.reversed())

    for i in 0 ..< types.count {
      let type = types[i]

      if type == "Null" {
        continue
      }

      if type == "list" || type == "Array" {
        if i > 0 {
          types[i - 1] = "<\(types[i - 1])"
          types[0] = "\(types[0])>"
        }
      } else if type == "map" {
        if i > 0 {
          types[i - 1] = "<\(types[i - 1]),"
          types[0] = "\(types[0])>"
        }
      }
    }

    types = Array(types.reversed())
    return types.joined()
  }
}
