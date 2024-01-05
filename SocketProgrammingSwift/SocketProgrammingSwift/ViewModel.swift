//
//  ViewModel.swift
//  SocketProgrammingSwift
//
//  Created by 김동준 on 1/1/24
//

import Foundation
import Socket
import SwiftUI
import Combine

class ViewModel: ObservableObject {
    @Published var myIPAddressString: String = ""
    @Published var counter = 0
    private var hostServerSocket: Socket?
    private var serverConnectedSocket: Socket? // 서버와 연결관계를 갖는 소켓
    private var linkedClientSocket: Socket?
    @Published var serverResponse: String = ""
    @Published var clientResponse: String = ""
    private let bufferSize: Int = 4096
    
    var cancellables: Set<AnyCancellable> = []

    let port: Int = 12345
    var hostAddress: String = "192.168.0.101"
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.counter += 1
            }
        }
    }
    
    func setHostIPAddress(ip: String) {
        hostAddress = ip
    }
    
    func getIPButtonTapped() {
        myIPAddressString = getIPAddress() ?? "Cannot get IP Address!"
    }
    
    func getIPAddress() -> String? {
        var address: String?

            // Get list of all interfaces on the local machine:
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0,
                let firstAddr = ifaddr else { return nil }
            
            // For each interface ...
            for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                let interface = ifptr.pointee
                
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // Check interface name:
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {

                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)

            return address
    }
    
    func startServer() {
        DispatchQueue.global(qos: .background).async {
            do {
                self.hostServerSocket = try Socket.create(family: .inet)
                guard let server = self.hostServerSocket else { return }
                
                try server.listen(on: self.port)
                guard let server = self.hostServerSocket else { return }
                self.hostServerSocket = server
                
                repeat {
                    let clientSocket = try server.acceptClientConnection()
                    print("Accepted connection from: \(clientSocket.remoteHostname)")
                    self.linkedClientSocket = clientSocket
                    var readData = Data(capacity: self.bufferSize)
                    
                    repeat {
                        self.readDataOnServerSocket(socket: clientSocket)
                            .sink(
                                receiveCompletion: {_ in},
                                receiveValue: { data in
                                    DispatchQueue.main.async {
                                        self.clientResponse = data
                                    }
                                }).store(in: &self.cancellables)
                    } while true
                } while true
                
            } catch let error {
                print("start Server error occured! \(error)")
            }
        }
    }
    
    func stopServer() {
        if let server = hostServerSocket {
            server.close()
            print("소켓 닫음")
        } else {
            print("stop server에서 scoket nil error")
        }
    }
    
    func readDataOnServerSocket(socket: Socket) -> Future<String, Error> {
        var readData = Data(capacity: self.bufferSize)

        return Future { promise in
            do {
                let bytesRead = try socket.read(into: &readData)

                if (bytesRead > 0) {
                    guard let response = String(data: readData, encoding: .utf8) else { return }
                    promise(.success(response))
                    readData.removeAll()
                }
            } catch let error {
                promise(.failure(error))
            }
        }
    }
    
    func startClient() {
        do {
            self.serverConnectedSocket = try Socket.create(family: .inet)
            guard let client = self.serverConnectedSocket else { return }
            try client.connect(to: self.hostAddress, port: Int32(self.port))
            
            // echoClient.write : 클라이언트 -> 서버로 보냄
            try self.serverConnectedSocket?.write(from: "hand-shaking ok")
            DispatchQueue.global(qos: .background).async {
                repeat {
                    self.readDataOnClientSocket(client: client)
                        .sink(
                            receiveCompletion: {_ in},
                            receiveValue: { data in
                                DispatchQueue.main.async {
                                    self.serverResponse = data
                                }
                            }).store(in: &self.cancellables)
                    } while true
                }
            } catch let error {
            print("start Client error occured! \(error)")
        }
    }
    
    func readDataOnClientSocket(client: Socket) -> Future<String, Error> {
        var readData = Data(capacity: self.bufferSize)

        return Future { promise in
            do {
                let bytesRead = try client.read(into: &readData)

                if (bytesRead > 0) {
                    guard let response = String(data: readData, encoding: .utf8) else { return }
                    promise(.success(response))
                    readData.removeAll()
                }
            } catch let error {
                promise(.failure(error))
            }
        }
    }
    
    func stopClient() {
        if let client = serverConnectedSocket {
            client.close()
            print("Client close Success!")
        } else {
            print("Client Close Failed!")
        }
        
        if let linkedClient = linkedClientSocket {
            linkedClient.close()
            print("linkedClient close Success!")
        } else {
            print("linkedClient Close Failed!")
        }
    }
    
    func sendMessageToServer(_ inputString: String) {
        print("서버로 보낼 스트링 : [\(inputString)]")
        do {
            if let clientSocket = serverConnectedSocket {
                // echoClient.write : 클라 -> 서버
                try clientSocket.write(from: inputString)
                print("서버로 보냈다.")
            } else {
                print("send Message Error")
            }
        } catch {
            print("send Message Exception")
        }
    }
    
    func sendMessageToClient(_ inputString: String) {
        print("클라로 보낼 스트링 : [\(inputString)]")
        do {
            if let hostServerSocket = linkedClientSocket {
                try hostServerSocket.write(from: inputString)
                print("클라로 보냈다.")
            } else {
                print("send Message Error")
            }
        } catch {
            print("send Message Exception")
        }
    }
    
    func printCurrentThread() {
        if Thread.isMainThread {
            print("Currently on the main thread.")
        } else {
            if let currentThreadName = Thread.current.name, !currentThreadName.isEmpty {
                print("Currently on a background thread with name: \(currentThreadName)")
            } else {
                print("Currently on an unnamed background thread.")
            }
        }
    }
}
