//
//  MessageBox.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

public struct MessageBox: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var text: String = ""
    @State private var selectedModel: String = ""
    
    private let messageBoxRadius = 15.0
    private let availableModels: [String]
    private let placeholder: String
    
    public init(models: [String], placeholder: String = "How can I help you today?") {
        self.availableModels = models
        self.selectedModel = models.first ?? ""
        self.placeholder = placeholder
    }
    
    public var body: some View {
        VStack {
            TextField("", text: $text)
                .font(.sansFont(size: 14))
                .textFieldStyle(.plain)
                .padding(20)
                .introspect(.textField, on: .macOS(.v10_15...)) { textField in
                    let attrs = [NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(0.8),
                                 NSAttributedString.Key.font: NSFont(name: "Anthropic Sans Web Text", size: 14)]
                    let placeholderString = NSAttributedString(string: placeholder, attributes: attrs)
                    (textField.cell as? NSTextFieldCell)?.placeholderAttributedString = placeholderString

                }
            
            HStack(spacing: 20) {
                Spacer()
                
                Button {
                    
                } label: {
                    HStack(spacing: 5) {
                        Text("\(availableModels[0])")
                        Image(systemSymbol: .chevronDown)
                            .foregroundStyle(.gray)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    
                } label: {
                    Image(systemSymbol: .arrowUp)
                        .foregroundStyle(text.isEmpty ? .gray.opacity(0.7) : .white)
                        .padding(7)
                }
                .buttonStyle(.plain)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(text.isEmpty ? (colorScheme == .dark ? Color(hex: "804937") : Color(hex: "E4B1A0")) : Color(hex: "C66240"))
                }
            }
            .padding()
        }
        .background {
            RoundedRectangle(cornerRadius: messageBoxRadius)
                .fill(colorScheme == .dark ? Color(hex: "30302E") : .white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: messageBoxRadius)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .enableInjection()
    }
    
}

#Preview {
    MessageBox(models: ["Sonnet 4.6"])
}
