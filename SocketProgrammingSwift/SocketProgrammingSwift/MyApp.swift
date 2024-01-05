//
//  ContentView.swift
//  SocketProgrammingSwift
//
//  Created by 김동준 on 1/1/24
//

import SwiftUI
import Combine

struct MyApp: View {
    @StateObject private var viewModel = ViewModel()
    @State var hostIPAddress: String = ""
    @State var serverTextField: String = ""
    @State var clientTextField: String = ""
    
    var cancellable = Set<AnyCancellable>()

    var body: some View {
        VStack {
            Text("Timer : [\(viewModel.counter)]")
            Text("From Server Response")
            Text("[\(viewModel.serverResponse)]")
            Text("From Client Response")
            Text("[\(viewModel.clientResponse)]")

            Text("IP Address : \(viewModel.myIPAddressString)")
            
            HStack {
                TextField(
                    "호스트 아이피 주소",
                    text: $hostIPAddress
                )
                .padding(.vertical, 8)
                .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.setHostIPAddress(ip: hostIPAddress)
                } label: {
                    Text("Set")
                }
            }
            
            TextField(
                "서버측으로 보내는 메시지",
                text: $serverTextField
            )
            .padding(.vertical, 8)
            .textFieldStyle(.roundedBorder)
            
            TextField(
                "클라이언트로 보내는 메시지",
                text: $clientTextField
            )
            .padding(.vertical, 8)
            .textFieldStyle(.roundedBorder)
            
            Button {
                viewModel.getIPButtonTapped()
            } label: {
                Text("Get IP Address")
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(.black)
            }
            
            HStack {
                Button {
                    viewModel.startServer()
                } label: {
                    Text("Start Server")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        .background(.black)
                }
                Button {
                    viewModel.stopServer()
                } label: {
                    Text("Stop Server")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        .background(.black)
                }
            }
            
            HStack {
                Button {
                    viewModel.startClient()
                } label: {
                    Text("Start Client")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        .background(.black)
                }
                
                Button {
                    viewModel.stopClient()
                } label: {
                    Text("Stop Client")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 20)
                        .background(.black)
                }
            }
            
            Button {
                print("버튼에서 \(serverTextField)")
                viewModel.sendMessageToServer(serverTextField)
            } label: {
                Text("Msg To Client -> Server")
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(.black)
            }
            Button {
                viewModel.sendMessageToClient(clientTextField)
            } label: {
                Text("Msg To Server -> Client")
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(.black)
            }.onAppear{
                viewModel.startTimer()
            }

        }.padding()
    }
}

#Preview {
    MyApp()
}
