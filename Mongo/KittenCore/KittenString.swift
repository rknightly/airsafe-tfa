import Foundation

public protocol KittenString {
    var kittenBytes: KittenBytes { get }
}

extension String : KittenString {
    public var kittenBytes: KittenBytes {
        return KittenBytes([UInt8](self.utf8))
    }
}

extension StaticString : KittenString {
    public static func ==(lhs: StaticString, rhs: StaticString) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public var hashValue: Int {
        return self.kittenBytes.hashValue
    }
    
    public var kittenBytes: KittenBytes {
        var data = [UInt8](repeating: 0, count: self.utf8CodeUnitCount)
        memcpy(&data, self.utf8Start, data.count)
        
        return KittenBytes(data)
    }
}

public struct KittenBytes : Hashable, KittenString, SimpleConvertible, ExpressibleByStringLiteral, Comparable {
    public static func <(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return true
            }
            
            if byte > rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    public static func >(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return false
            }
            
            if byte > rhs.bytes[position] {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    public static func ==(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        return lhs.bytes == rhs.bytes
    }
    
    public init(stringLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    public init(unicodeScalarLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    public init(extendedGraphemeClusterLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    public var hashValue: Int {
        guard bytes.count > 0 else {
            return 0
        }
        
        var h = 0
        
        for i in 0..<bytes.count {
            h = 31 &* h &+ numericCast(bytes[i])
        }
        
        return h
    }
    
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let string = String(bytes: bytes, encoding: .utf8) as? S {
            return string
        }
        
        return nil
    }
    
    public let bytes: [UInt8]
    
    public var kittenBytes: KittenBytes { return self }
    
    public init(_ data: [UInt8]) {
        self.bytes = data
    }
}
