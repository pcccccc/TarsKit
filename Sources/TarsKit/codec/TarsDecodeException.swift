//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

// MARK: - TarsDecodeException

/// Tars 解码异常
struct TarsDecodeException: Error {
  /// 错误信息
  let message: String

  /// 初始化方法
  init(_ message: String) {
    self.message = message
  }
}

// MARK: CustomStringConvertible

/// 实现 CustomStringConvertible 协议以提供自定义描述
extension TarsDecodeException: CustomStringConvertible {
  var description: String {
    message
  }
}
