import Foundation

// MARK: - UniPacket

//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

class UniPacket: UniAttribute {
  private static let kUniPacketHeadSize = 4

  var package = RequestPacket()

  var servantName: String {
    get { package.sServantName }
    set { package.sServantName = newValue }
  }

  var funcName: String {
    get { package.sFuncName }
    set { package.sFuncName = newValue }
  }

  var requestId: Int {
    get { package.iRequestId }
    set { package.iRequestId = newValue }
  }

  override init() {
    super.init()
    package.iVersion = Constants.packetTypeTup3
  }

  override public func writeTo(_ os: TarsOutputStream) throws {
    try package.writeTo(os)
  }

  override public func readFrom(_ inputs: TarsInputStream) throws {
    try package.readFrom(inputs)
  }

  override func decode(_ buffer: Uint8List, index: Int = 0) throws {
    guard buffer.count >= Self.kUniPacketHeadSize else {
      throw PacketError.invalidBufferSize
    }

    var inputStream = TarsInputStream(buffer, pos: UniPacket.kUniPacketHeadSize + index)
    inputStream.setServerEncoding(encodeName)
    try readFrom(inputStream)

    version = package.iVersion

    inputStream = TarsInputStream(package.sBuffer)
    inputStream.setServerEncoding(encodeName)

    if package.iVersion == Constants.packetTypeTup {
      oldData = try inputStream.readMapMap(
        ["": ["": Uint8List([0x0])]],
        tag: 0,
        required: false)
    } else {
      newData = try inputStream.readMap(
        ["": Uint8List([0x0])],
        tag: 0,
        required: false)
    }
  }

  override func encode() throws -> Uint8List {
    guard !package.sServantName.isEmpty else {
      throw PacketError.invalidServantName
    }

    guard !package.sFuncName.isEmpty else {
      throw PacketError.invalidFuncName
    }

    let outputs = TarsOutputStream()
    outputs.setServerEncoding(encodeName)

    if package.iVersion == Constants.packetTypeTup {
      throw PacketError.unimplementedTupVersion
    } else {
      try outputs.write(newData, tag: 0)
    }

    package.sBuffer = outputs.toUint8List()

    let bodyOS = TarsOutputStream()
    bodyOS.setServerEncoding(encodeName)
    try writeTo(bodyOS)
    let body = bodyOS.toUint8List()
    let size = body.count

    let buffer = WriteBuffer()
    buffer.putInt32(Int32(size + Self.kUniPacketHeadSize), endian: .bigEndian)
    buffer.putUint8List(body)

    return Uint8List(buffer.done())
  }

  func setVersion(_ iVer: Int) {
    version = iVer
    package.iVersion = iVer
  }

  func getVersion() -> Int {
    package.iVersion
  }
}

// MARK: - PacketError

enum PacketError: Error {
  case invalidServantName
  case invalidFuncName
  case invalidBufferSize
  case unimplementedTupVersion
}
