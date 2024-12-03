//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

// MARK: - TupResultException

/// Tup 结果异常
struct TupResultException: Error {
  /// 错误码
  let code: Int

  /// 错误信息
  let message: String?

  /// 初始化方法
  init(_ code: Int, message: String? = nil) {
    self.code = code
    self.message = message
  }
}

// MARK: CustomStringConvertible

extension TupResultException: CustomStringConvertible {
  var description: String {
    "{code: \(code), message: \(message ?? "nil")}"
  }
}
