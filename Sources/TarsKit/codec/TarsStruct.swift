import Foundation

// MARK: - TarsStructType

//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

enum TarsStructType: Int {
  case byte = 0
  case short = 1
  case int = 2
  case long = 3
  case float = 4
  case double = 5
  case string1 = 6
  case string4 = 7
  case map = 8
  case list = 9
  case structBegin = 10
  case structEnd = 11
  case zeroTag = 12
  case simpleList = 13
}

// MARK: - DeepCopyable

public protocol DeepCopyable {
  func deepCopy() -> Self
}

// MARK: - TarsStruct

public protocol TarsStruct: DeepCopyable {
  /// Tars 最大字符串长度
  static var maxStringLength: Int { get }

  /// 写入到输出流
  func writeTo(_ outputStream: TarsOutputStream) throws

  /// 从输入流读取
  func readFrom(_ inputStream: TarsInputStream) throws

  /// 将结构转换为字符串表示
  func displayAsString(_ buffer: inout String, level: Int)
}

// MARK: - Default Implementation

extension TarsStruct {
  public static var maxStringLength: Int {
    Constants.maxStringLength
  }

  /// 将结构序列化为字节数组
  func toByteArray() throws -> Uint8List {
    let outputStream = TarsOutputStream()
    try writeTo(outputStream)
    return outputStream.toUint8List()
  }
}
