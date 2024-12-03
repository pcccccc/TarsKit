import Foundation

//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

class TarsUniPacket: UniPacket {
  override init() {
    super.init()
    package.iVersion = Constants.packetTypeTup3
    package.cPacketType = Constants.packetTypeTarsNormal
    package.iMessageType = 0
    package.iTimeout = 0
    package.sBuffer = Uint8List([0x0])
    package.context = [String: String]()
    package.status = [String: String]()
  }

  func setTarsVersion(_ version: Int) {
    setVersion(version)
  }

  func setTarsPacketType(_ packetType: Int) {
    package.cPacketType = packetType
  }

  func setTarsMessageType(_ messageType: Int) {
    package.iMessageType = messageType
  }

  func setTarsTimeout(_ timeout: Int) {
    package.iTimeout = timeout
  }

  func setTarsBuffer(_ buffer: Uint8List) {
    package.sBuffer = buffer
  }

  func setTarsContext(_ context: [String: String]) {
    package.context = context
  }

  func setTarsStatus(_ status: [String: String]) {
    package.status = status
  }

  func getTarsVersion() -> Int {
    package.iVersion
  }

  func getTarsPacketType() -> Int {
    package.cPacketType
  }

  func getTarsMessageType() -> Int {
    package.iMessageType
  }

  func getTarsTimeout() -> Int {
    package.iTimeout
  }

  func getTarsBuffer() -> Uint8List {
    package.sBuffer
  }

  func getTarsContext() -> [String: String]? {
    package.context
  }

  func getTarsStatus() -> [String: String]? {
    package.status
  }

  func getTarsResultCode() -> Int {
    guard
      let rcodeString = package.status[Constants.statusResultCode],
      let result = Int(rcodeString)
    else {
      return 0
    }
    return result
  }

  func getTarsResultDesc() -> String {
    guard let desc = package.status[Constants.statusResultDesc] else {
      return ""
    }
    return desc
  }
}
