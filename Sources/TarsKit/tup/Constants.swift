//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Foundation

// MARK: - Constants

enum Constants {
  static let statusGridKey = "STATUS_GRID_KEY"
  static let statusDyedKey = "STATUS_DYED_KEY"
  static let statusGridCode = "STATUS_GRID_CODE"
  static let statusSampleKey = "STATUS_SAMPLE_KEY"
  static let statusResultCode = "STATUS_RESULT_CODE"
  static let statusResultDesc = "STATUS_RESULT_DESC"

  static let invalidHashCode: Int = -1
  static let invalidGridCode: Int = -1

  static let packetTypeTarsNormal: Int = 0
  static let packetTypeTarsOneWay: Int = 1
  static let packetTypeTup: Int = 2
  static let packetTypeTup3: Int = 3

  static let maxStringLength: Int = 100 * 1024 * 1024
}
