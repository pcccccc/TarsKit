//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

// MARK: - TarsEncodeException

/// Tars 编码异常
struct TarsEncodeException: Error {
  /// 错误信息
  let message: String

  /// 初始化方法
  init(_ message: String) {
    self.message = message
  }
}

// MARK: CustomStringConvertible

/// 实现自定义描述
extension TarsEncodeException: CustomStringConvertible {
  var description: String {
    message
  }
}
