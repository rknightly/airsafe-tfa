import Foundation

public protocol Convertible {
    func convert<DT : DataType>(to type: DT.Type) -> DT.SupportedValue?
}

public protocol DataType {
    associatedtype Object: InitializableObject
    associatedtype Sequence: InitializableSequence
    associatedtype SupportedValue
}

public protocol SimpleConvertible : Convertible {
    func convert<S: Any>(_ type: S.Type) -> S?
}

extension SimpleConvertible {
    public func convert<DT>(to type: DT.Type) -> DT.SupportedValue? where DT : DataType {
        return self.convert(DT.SupportedValue.self)
    }
}

public protocol InitializableObject : InitializableSequence {
    associatedtype ObjectKey: Hashable
    associatedtype ObjectValue
    associatedtype SupportedValue = (ObjectKey, ObjectValue)
    
    var dictionaryRepresentation: [ObjectKey: ObjectValue] { get }
}

extension InitializableObject {
    public func convert<DT : DataType>(to type: DT.Type) -> DT.SupportedValue? {
        return self.convert(toObject: type) as? DT.SupportedValue
    }
    
    public func convert<DT>(toObject type: DT.Type) -> DT.Object where DT : DataType {
        return DT.Object(sequence: self.dictionaryRepresentation.flatMap { key, value in
            let newKey: DT.Object.ObjectKey
            
            if let key = key as? DT.Object.ObjectKey {
                newKey = key
            } else if let key = key as? SimpleConvertible {
                if let key = key.convert(DT.Object.ObjectKey.self) {
                    newKey = key
                } else {
                    return nil
                }
            } else if let key = key as? Convertible {
                if let key = key.convert(to: type) as? DT.Object.ObjectKey {
                    newKey = key
                } else {
                    return nil
                }
            } else {
                return nil
            }
            
            let key = newKey
            
            if let value = value as? DT.Object.ObjectValue {
                return (key, value) as? DT.Object.SupportedValue
            } else if let value = value as? Convertible {
                if let value: DT.SupportedValue = value.convert(to: type) {
                    return (key, value) as? DT.Object.SupportedValue
                }
            }
            
            return nil
        })
    }
    
    public func convert<DT>(toSequence type: DT.Type) -> DT.Sequence where DT : DataType {
        return DT.Sequence(sequence: self.dictionaryRepresentation.flatMap { _, value in
            if let value = value as? DT.Sequence.SupportedValue {
                return value
            } else if let value = value as? Convertible {
                if let value: DT.SupportedValue = value.convert(to: type) {
                    return value as? DT.Sequence.SupportedValue
                }
            }
            
            return nil
        })
    }
}

public protocol SerializableSequence : Convertible, Sequence {
    associatedtype SupportedValue
}

public protocol InitializableSequence : SerializableSequence {
    init<S: Sequence>(sequence: S) where S.Iterator.Element == SupportedValue
}

extension SerializableSequence {
    public func convert<DT>(to type: DT.Type) -> DT.SupportedValue? where DT : DataType {
        var iterator = self.makeIterator()
        
        return DT.Sequence(sequence: self.flatMap { value in
            if let value = iterator.next() {
                if let value = value as? DT.Sequence.SupportedValue {
                    return value
                } else if let value = value as? Convertible {
                    if let value: DT.SupportedValue = value.convert(to: type) {
                        return value as? DT.Sequence.SupportedValue
                    }
                }
            }
            
            return nil
        }) as? DT.SupportedValue
    }
}

extension AnyIterator : SerializableSequence {
    public typealias SupportedValue = Any
}

extension Dictionary : InitializableObject {
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == (Key, Value) {
        var dict = [Key: Value]()
        
        for (key, value) in sequence {
            dict[key] = value
        }
        
        self = dict
    }
    
    public typealias SequenceType = Array<Value>
    
    public var dictionaryRepresentation: [Key : Value] {
        return self
    }
}

extension Array : InitializableSequence {
    public typealias SupportedValue = Element
    
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == Element {
        self = Array(sequence)
    }
}

extension String : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let kittenBytes = self.kittenBytes as? S {
            return kittenBytes
        }
        
        if Double.self is S, let number = Double(self) as? S {
            return number
        }
        
        if Int.self is S, let number = Int(self) as? S {
            return number
        }
        
        if UInt.self is S, let number = UInt(self) as? S {
            return number
        }
        
        if UInt64.self is S, let number = UInt64(self) as? S {
            return number
        }
        
        if UInt32.self is S, let number = UInt32(self) as? S {
            return number
        }
        
        if UInt16.self is S, let number = UInt16(self) as? S {
            return number
        }
        
        if UInt8.self is S, let number = UInt8(self) as? S {
            return number
        }
        
        if Int64.self is S, let number = Int64(self) as? S {
            return number
        }
        
        if Int32.self is S, let number = Int32(self) as? S {
            return number
        }
        
        if Int16.self is S, let number = Int16(self) as? S {
            return number
        }
        
        if Int8.self is S, let number = Int8(self) as? S {
            return number
        }
        
        return nil
    }
}

extension StaticString : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let kittenBytes = self.kittenBytes as? S {
            return kittenBytes
        }
        
        if let string = String(self.unicodeScalar) as? S {
            return string
        }
        
        return nil
    }
}

extension Bool : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

extension Data : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

extension NSRegularExpression : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

extension NSNull : SimpleConvertible {
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

public typealias Null = NSNull
