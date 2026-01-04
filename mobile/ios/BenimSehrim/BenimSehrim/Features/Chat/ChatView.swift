import SwiftUI

struct ChatView: View {
    let chatId: String
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding()
                }
                
                VStack(alignment: .leading) {
                    Text(viewModel.partnerName)
                        .font(.headline)
                    Text("Çevrimiçi")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
            }
            .background(Color.white)
            .shadow(radius: 1)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.systemGray6))
            
            // Input Area
            HStack {
                TextField("Mesaj yazın...", text: $viewModel.messageInput)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.green)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isMine == true { Spacer() }
            
            VStack(alignment: message.isMine == true ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isMine == true ? Color.green : Color.white)
                    .foregroundColor(message.isMine == true ? .white : .black)
                    .cornerRadius(16)
                    .shadow(radius: 1)
                
                Text(message.createdAt)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if message.isMine != true { Spacer() }
        }
    }
}
