//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

/// 用于封装 Tup 响应的泛型结构体
struct TupResponse<T> {
  var code: Int = 0

  var response: T?

  init(code: Int = 0, response: T? = nil) {
    self.code = code
    self.response = response
  }
}
