import Foundation

// MARK: - RequestPacket

//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

final class RequestPacket: TarsStruct {
  private nonisolated(unsafe) static var cacheBuffer = Uint8List([0x0])
  private static let cacheContext = ["": ""]
  private static let cacheStatus = ["": ""]

  var iVersion: Int = 0
  var cPacketType: Int = 0
  var iMessageType: Int = 0
  var iRequestId: Int = 0
  var sServantName: String = ""
  var sFuncName: String = ""
  var sBuffer: Uint8List
  var iTimeout: Int = 0
  var context: [String: String]
  var status: [String: String]

  init(
    iVersion: Int = 0,
    cPacketType: Int = 0,
    iMessageType: Int = 0,
    iRequestId: Int = 0,
    sServantName: String = "",
    sFuncName: String = "",
    sBuffer: Uint8List = [],
    iTimeout: Int = 0,
    context: [String: String] = [:],
    status: [String: String] = [:]
  ) {
    self.iVersion = iVersion
    self.cPacketType = cPacketType
    self.iMessageType = iMessageType
    self.iRequestId = iRequestId
    self.sServantName = sServantName
    self.sFuncName = sFuncName
    self.sBuffer = sBuffer
    self.iTimeout = iTimeout
    self.context = context
    self.status = status
  }

  func writeTo(_ outputs: TarsOutputStream) throws {
    try outputs.write(iVersion, tag: 1)
    try outputs.write(cPacketType, tag: 2)
    try outputs.write(iMessageType, tag: 3)
    try outputs.write(iRequestId, tag: 4)
    try outputs.write(sServantName, tag: 5)
    try outputs.write(sFuncName, tag: 6)
    try outputs.write(sBuffer, tag: 7)
    try outputs.write(iTimeout, tag: 8)
    try outputs.write(context, tag: 9)
    try outputs.write(status, tag: 10)
  }

  func readFrom(_ inputs: TarsInputStream) throws {
    iVersion = try inputs.read(&iVersion, tag: 1, required: false)
    cPacketType = try inputs.read(&cPacketType, tag: 2, required: false)
    iMessageType = try inputs.read(&iMessageType, tag: 3, required: false)
    iRequestId = try inputs.read(&iRequestId, tag: 4, required: false)
    sServantName = try inputs.read(&sServantName, tag: 5, required: false)
    sFuncName = try inputs.read(&sFuncName, tag: 6, required: false)
    sBuffer = try inputs.read(&RequestPacket.cacheBuffer, tag: 7, required: false)
    iTimeout = try inputs.read(&iTimeout, tag: 8, required: false)
    context = try inputs.readMap(RequestPacket.cacheContext, tag: 9, required: false)
    status = try inputs.readMap(RequestPacket.cacheStatus, tag: 10, required: false)
  }

  func displayAsString(_ os: inout String, level: Int) {
    TarsDisplayer(os, level: level)
      .display(iVersion, "iVersion")
      .display(cPacketType, "cPacketType")
      .display(iMessageType, "iMessageType")
      .display(iRequestId, "iRequestId")
      .display(sServantName, "sServantName")
      .display(sFuncName, "sFuncName")
      .display(sBuffer, "sBuffer")
      .display(iTimeout, "iTimeout")
      .display(context, "context")
      .display(status, "status")
  }

  func deepCopy() -> RequestPacket {
    let copy = RequestPacket()
    copy.iVersion = iVersion
    copy.cPacketType = cPacketType
    copy.iMessageType = iMessageType
    copy.iRequestId = iRequestId
    copy.sServantName = sServantName
    copy.sFuncName = sFuncName
    copy.sBuffer = sBuffer
    copy.iTimeout = iTimeout
    copy.context = context.deepCopy()
    copy.status = status.deepCopy()
    return copy
  }
}

extension Dictionary {
  func deepCopy() -> [Key: Value] where Key: Hashable {
    Dictionary(uniqueKeysWithValues: map { key, value in
      (key, value)
    })
  }
}
