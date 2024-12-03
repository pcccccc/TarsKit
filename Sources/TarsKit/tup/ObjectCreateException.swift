//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

/// 对象创建异常
struct ObjectCreateException: Error {
  /// 错误信息
  private let message: String

  /// 初始化方法
  init(_ message: String) {
    self.message = message
  }
}
