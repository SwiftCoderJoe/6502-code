import Foundation

var binaryData = Data(capacity: 32768)

binaryData.append(contentsOf: [
    0xa9, 0xff,             // lda #$ff
    0x8d, 0x02, 0x60,       // sta $6002

    0xa9, 0x55,             // lda #$55
    0x8d, 0x00, 0x60,       // sta $6000

    0xa9, 0xaa,             // lda #$aa
    0x8d, 0x00, 0x60,       // sta $6000

    0x4c, 0x05, 0x80,       // jmp $8005
])

binaryData.append(contentsOf: 
    Array<UInt8>(repeating: 0xea, count: 32768 - binaryData.count)
)

binaryData[0x7ffc] = 0x00
binaryData[0x7ffd] = 0x80

guard let currentDirectoryURL = Process().currentDirectoryURL else { throw DirectoryFetchError() }

try binaryData.write(to: currentDirectoryURL.appending(path: "program.bin"))


struct DirectoryFetchError: Error { }