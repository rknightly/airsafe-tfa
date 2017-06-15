//
// This source file is part of the MongoKitten open source project
//
// Copyright (c) 2016 - 2017 OpenKitten and the MongoKitten project authors
// Licensed under MIT
//
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/LICENSE.md for license information
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/CONTRIBUTORS.md for the list of MongoKitten project authors
//

import Foundation
import Dispatch

#if os(macOS) || os(iOS)
    import Security
    import Darwin
#else
    import KittenCTLS
    import Glibc
#endif

public final class MongoSocket: MongoTCP {
    public private(set) var plainClient: Int32
    
    #if os(macOS) || os(iOS)
    private let sslClient: SSLContext?
    #else
    fileprivate static var initialized: Bool = false
    private let sslClient: UnsafeMutablePointer<SSL>?
    private let sslMethod: UnsafePointer<SSL_METHOD>?
    private let sslContext: UnsafeMutablePointer<SSL_CTX>?
    #endif
    
    private var sslEnabled = false
    
    private static let socketQueue = DispatchQueue(label: "org.mongokitten.socketQueue", qos: DispatchQoS.userInteractive)
    
    public var onRead: ReadCallback
    public var onError: ErrorCallback
    
    private let operationLock = NSLock()
    
    private let readSource: DispatchSourceRead
    
    public init(address hostname: String, port: UInt16, options: [String: Any], onRead: @escaping ReadCallback, onError: @escaping ErrorCallback) throws {
        self.sslEnabled = options["sslEnabled"] as? Bool ?? false
        self.onRead = onRead
        self.onError = onError
        
        var criteria = addrinfo.init()
        
        let hostname = hostname == "localhost" ? "127.0.0.1" : hostname
        
        #if os(macOS) || os(iOS)
            criteria.ai_socktype = Int32(SOCK_STREAM)
        #else
            criteria.ai_socktype = Int32(SOCK_STREAM.rawValue)
        #endif
        
        criteria.ai_family = Int32(AF_UNSPEC)
        criteria.ai_flags = AI_PASSIVE
        criteria.ai_protocol = Int32(IPPROTO_TCP)
        
        var serverinfo: UnsafeMutablePointer<addrinfo>? = nil
        let ret = getaddrinfo(hostname, port.description, &criteria, &serverinfo)
        
        guard let addrList = serverinfo else { throw Error.ipAddressResolutionFailed }
        defer { freeaddrinfo(addrList) }
        
        guard let addrInfo = addrList.pointee.ai_addr else { throw Error.ipAddressResolutionFailed }
        
        let ptr = UnsafeMutablePointer<sockaddr_storage>.allocate(capacity: 1)
        ptr.initialize(to: sockaddr_storage())
        
        switch Int32(addrInfo.pointee.sa_family) {
        case Int32(AF_INET):
            let addr = UnsafeMutablePointer<sockaddr_in>.init(OpaquePointer(addrInfo))!
            let specPtr = UnsafeMutablePointer<sockaddr_in>(OpaquePointer(ptr))
            specPtr.assign(from: addr, count: 1)
        case Int32(AF_INET6):
            let addr = UnsafeMutablePointer<sockaddr_in6>(OpaquePointer(addrInfo))!
            let specPtr = UnsafeMutablePointer<sockaddr_in6>(OpaquePointer(ptr))
            specPtr.assign(from: addr, count: 1)
        default:
            throw Error.ipAddressResolutionFailed
        }
        
        #if os(macOS) || os(iOS)
            self.plainClient = socket(Int32(addrInfo.pointee.sa_family), SOCK_STREAM, Int32(IPPROTO_TCP))
        #else
            self.plainClient = socket(Int32(addrInfo.pointee.sa_family), Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP))
        #endif
        
        signal(SIGPIPE, SIG_IGN)
        
        guard plainClient >= 0 else {
            throw Error.cannotConnect
        }
        
        if Int32(addrInfo.pointee.sa_family) == Int32(AF_INET) {
            connect(self.plainClient, UnsafeMutablePointer<sockaddr>(OpaquePointer(ptr)), socklen_t(MemoryLayout<sockaddr_in>.size))
        } else {
            connect(self.plainClient, UnsafeMutablePointer<sockaddr>(OpaquePointer(ptr)), socklen_t(MemoryLayout<sockaddr_in6>.size))
        }
        
        
        #if os(macOS) || os(iOS)
            var val = 1
            setsockopt(self.plainClient, SOL_SOCKET, SO_NOSIGPIPE, &val, socklen_t(MemoryLayout<Int>.stride))
            
            if sslEnabled {
                guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
                    throw Error.cannotCreateContext
                }
                
                SSLSetIOFuncs(context, { context, data, length in
                    let context = context.bindMemory(to: Int32.self, capacity: 1).pointee
                    var read = Darwin.recv(context, data, length.pointee, 0)
                    
                    length.assign(from: &read, count: 1)
                    return 0
                }, { context, data, length in
                    let context = context.bindMemory(to: Int32.self, capacity: 1).pointee
                    var written = Darwin.send(context, data, length.pointee, 0)
                    
                    length.assign(from: &written, count: 1)
                    return 0
                })
                
                SSLSetConnection(context, &self.plainClient)
                
                var string = Array(hostname.utf8).map {
                    Int8($0)
                }
                
                SSLSetPeerDomainName(context, &string, string.count)
                
                if let path = options["CAFile"] as? String, let data = FileManager.default.contents(atPath: path) {
                    let bytes = [UInt8](data)
                    
                    if let certBytes = CFDataCreate(kCFAllocatorDefault, bytes, data.count), let _ = SecCertificateCreateWithData(kCFAllocatorDefault, certBytes) {
//                        SSLSetCertificateAuthorities(context, cert, true)
                    }
                }
                
                _ = SSLHandshake(context)
                
                self.sslClient = context
            } else {
                self.sslClient = nil
            }
        #else
            if sslEnabled {
                let verifyCertificate = !(options["invalidCertificateAllowed"] as? Bool ?? false)
//                let verifyHost = !(options["invalidHostNameAllowed"] as? Bool ?? false)
                
                if !MongoSocket.initialized {
                    SSL_library_init()
                    SSL_load_error_strings()
                    OPENSSL_config(nil)
                    OPENSSL_add_all_algorithms_conf()
                    MongoSocket.initialized = true
                }
                
                let method = SSLv23_client_method()
                
                guard let ctx = SSL_CTX_new(method) else {
                    throw Error.cannotCreateContext
                }
                
                self.sslContext = ctx
                self.sslMethod = method
                
                SSL_CTX_ctrl(ctx, SSL_CTRL_MODE, SSL_MODE_AUTO_RETRY, nil)
                SSL_CTX_ctrl(ctx, SSL_CTRL_OPTIONS, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION, nil)
                
                if !verifyCertificate {
                    SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, nil)
                }
                
                guard  SSL_CTX_set_cipher_list(ctx, "DEFAULT") == 1 else {
                    throw Error.cannotCreateContext
                }
                
//SSL_set_tlsext_host_name
//                guard SSL_set_tlsext_host_name
                
                if let CAFile = options["CAFile"] as? String {
                    SSL_CTX_load_verify_locations(ctx, CAFile, nil)
                }
                
                guard let ssl = SSL_new(ctx) else {
                    throw Error.cannotConnect
                }
                
                self.sslClient = ssl
                
                guard SSL_set_fd(ssl, plainClient) == 1 else {
                    throw Error.cannotConnect
                }
                
                // TODO: Hostname verification
                
                guard SSL_connect(ssl) == 1, SSL_do_handshake(ssl) == 1 else {
                    throw Error.cannotConnect
                }
            } else {
                sslClient = nil
                sslMethod = nil
                sslContext = nil
            }
        #endif
        
        self.readSource = DispatchSource.makeReadSource(fileDescriptor: self.plainClient, queue: MongoSocket.socketQueue)
        
        let incomingBuffer = Buffer()
        
        self.readSource.setEventHandler(qos: .userInteractive) {
            do {
                var read = 0
                
                if self.sslEnabled {
                    #if os(macOS) || os(iOS)
                        SSLRead(self.sslClient!, incomingBuffer.pointer, Int(UInt16.max), &read)
                    #else
                        read = Int(SSL_read(self.sslClient!, incomingBuffer.pointer, Int32(UInt16.max)))
                    #endif
                } else {
                    #if os(macOS) || os(iOS)
                        read = Darwin.recv(self.plainClient, incomingBuffer.pointer, Int(UInt16.max), 0)
                    #else
                        read = Glibc.recv(self.plainClient, incomingBuffer.pointer, Int(UInt16.max), 0)
                    #endif
                }
                
                incomingBuffer.usedCapacity = read
                
                guard read > -1 else {
                    throw Error.cannotRead
                }
                
                self.onRead(incomingBuffer.pointer, incomingBuffer.usedCapacity)
            } catch {
                self.onError(error)
            }
        }
        
        self.readSource.resume()
    }
    
    enum Error : Swift.Error {
        case disconnectedByPeer
        case cannotSendData
        case cannotCreateContext
        case cannotRead
        case cannotConnect
        case ipAddressResolutionFailed
    }
    
    /// Sends the data to the other side of the connection
    public func send(data pointer: UnsafePointer<UInt8>, withLengthOf length: Int) throws {
        self.operationLock.lock()
        defer { self.operationLock.unlock() }
        
        let binary = Array(UnsafeBufferPointer<UInt8>(start: pointer, count: length))
        
        if self.sslEnabled {
            #if os(macOS) || os(iOS)
                var ditched = binary.count
                SSLWrite(self.sslClient!, binary, binary.count, &ditched)
                
                guard ditched == binary.count else {
                    throw Error.cannotSendData
                }
            #else
                var total = 0
                guard let baseAddress = UnsafeBufferPointer<UInt8>(start: binary, count: binary.count).baseAddress else {
                    throw Error.cannotSendData
                }
                
                while total < binary.count {
                    let sent = SSL_write(self.sslClient!, baseAddress.advanced(by: total), Int32(binary.count))
                    
                    total = total &+ numericCast(sent)
                    
                    guard sent > 0 else {
                        throw Error.cannotSendData
                    }
                }
            #endif
        } else {
            #if os(macOS) || os(iOS)
                guard Darwin.send(self.plainClient, binary, binary.count, 0) == binary.count else {
                    throw Error.cannotSendData
                }
            #else
                guard Glibc.send(self.plainClient, binary, binary.count, 0) == binary.count else {
                    throw Error.cannotSendData
                }
            #endif
        }
    }
    
    /// Closes the connection
    public func close() throws {
        if sslEnabled {
            #if os(macOS) || os(iOS)
                SSLClose(sslClient!)
                _ = Darwin.close(plainClient)
            #else
                _ = Glibc.close(plainClient)
            #endif
        } else {
            #if os(macOS) || os(iOS)
                _ = Darwin.close(plainClient)
            #else
                _ = Glibc.close(plainClient)
            #endif
        }
    }
    
    public var isConnected: Bool {
        var error = 0
        var len: socklen_t = 4
        
        getsockopt(self.plainClient, SOL_SOCKET, SO_ERROR, &error, &len)
        
        guard error == 0 else {
            return false
        }
        
        return true
    }
    
    deinit {
        _ = try? close()
        
        #if os(Linux)
            SSL_CTX_free(sslContext)
        #endif
    }
}
