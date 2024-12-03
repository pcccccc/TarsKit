//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

/// Tars 数据结构显示器
public class TarsDisplayer {
  private var sb: String
  private let level: Int

  public init(_ sb: String = "", level: Int = 0) {
    self.sb = sb
    self.level = level
  }

  @discardableResult
  public func display(_ value: Any, _ fieldName: String?) -> TarsDisplayer {
    switch value {
    case let value as Bool:
      displayBool(value, fieldName)
    case let value as Int:
      displayInt(value, fieldName)
    case let value as Double:
      displayDouble(value, fieldName)
    case let value as String:
      displayString(value, fieldName)
    case let value as Uint8List:
      displayData(value, fieldName)
    case let value as [Any]:
      displayArray(value, fieldName)
    case let value as [AnyHashable: Any]:
      displayMap(value, fieldName)
    case let value as any TarsStruct:
      displayTarsStruct(value, fieldName)
    default:
      self
    }
  }

  @discardableResult
  func displayBool(_ value: Bool, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    sb += value ? "T\n" : "F\n"
    return self
  }

  @discardableResult
  func displayInt(_ value: Int, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    sb += "\(value)\n"
    return self
  }

  @discardableResult
  func displayDouble(_ value: Double, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    sb += "\(value)\n"
    return self
  }

  @discardableResult
  func displayString(_ value: String?, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    if let value {
      sb += "\(value)\n"
    } else {
      sb += "null\n"
    }
    return self
  }

  @discardableResult
  func displayData(_ value: Uint8List?, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    guard let value else {
      sb += "null\n"
      return self
    }

    if value.isEmpty {
      sb += "0, []\n"
      return self
    }

    sb += "\(value.count), [\n"
    let subDisplayer = TarsDisplayer(sb, level: level + 1)
    for byte in value {
      subDisplayer.display(Int(byte), nil)
    }
    display("]", nil)
    return self
  }

  @discardableResult
  func displayMap(_ value: [AnyHashable: Any]?, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    guard let value else {
      sb += "null\n"
      return self
    }

    if value.isEmpty {
      sb += "0, {}\n"
      return self
    }

    sb += "\(value.count), {\n"
    let subDisplayer1 = TarsDisplayer(sb, level: level + 1)
    let subDisplayer2 = TarsDisplayer(sb, level: level + 2)

    for (key, val) in value {
      subDisplayer1.display("(", nil)
      subDisplayer2.display(key, nil)
      subDisplayer2.display(val, nil)
      subDisplayer1.display(")", nil)
    }
    display("}", nil)
    return self
  }

  @discardableResult
  func displayArray(_ value: [Any]?, _ fieldName: String?) -> TarsDisplayer {
    printSpace(fieldName)
    guard let value else {
      sb += "null\n"
      return self
    }

    if value.isEmpty {
      sb += "0, []\n"
      return self
    }

    sb += "\(value.count), [\n"
    let subDisplayer = TarsDisplayer(sb, level: level + 1)
    for item in value {
      subDisplayer.display(item, nil)
    }
    display("]", nil)
    return self
  }

  @discardableResult
  func displayTarsStruct(_ value: (any TarsStruct)?, _ fieldName: String?) -> TarsDisplayer {
    display("{", fieldName)
    if let value {
      value.displayAsString(&sb, level: level + 1)
    } else {
      sb += "\tnull"
    }
    display("}", nil)
    return self
  }

  private func printSpace(_ fieldName: String?) {
    for _ in 0 ..< level {
      sb += "\t"
    }

    if let name = fieldName {
      sb += "\(name): "
    }
  }
}
