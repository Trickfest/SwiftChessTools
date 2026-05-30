import SwiftUI

import ChessCore
import ChessUI

struct ContentView: View {
    var body: some View {
        VStack {
            TestBoard()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }
}

public struct TestBoard: View {
    static let POSITION = "5k2/1P2bn2/8/8/8/3Q4/3K4/8 w - - 0 1"
    
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    
    @State var size: CGFloat = 350
    
    @Bindable var boardModel = ChessBoardModel(fen: POSITION,
                                               perspective: .white,
                                               colorScheme: .light)
    
    @State var fen = POSITION
    
    var backgroundAnimationStartDate = Date()

    private var isResetDisabled: Bool {
        boardModel.fen == Self.POSITION
    }

    private var resetButtonBackground: Color {
        isResetDisabled ? Color(red: 0.98, green: 0.80, blue: 0.84) : .red
    }

    private var resetButtonForeground: Color {
        isResetDisabled ? Color(red: 0.45, green: 0.02, blue: 0.08) : .white
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            VStack {}.frame(height: 50)
            
            Text("ChessUI Sample")
                .font(.title)
                .fontWeight(.bold)
            
            ChessBoardView(model: boardModel)
                .onMove { move, isLegal, _, _, coordinateMove, _ in
                    print("Move: FEN: \(boardModel.fen) - coordinate move: \(coordinateMove)")
                    
                    if !isLegal {
                        print("Illegal move: \(coordinateMove)")
                        return
                    }
                    
                    boardModel.game.apply(move: move)
                    boardModel.setFEN(FENSerializer().fen(from: boardModel.game.position), animatedMove: move)
                }
                .frame(width: size, height: size)
                .padding(5)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            
            VStack(alignment: .leading) {
                Text("FEN Notation:")
                    .fontWeight(.medium)
                
                TextField("Enter FEN", text: $fen)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .onChange(of: fen) { _, newValue in
                        if !FENValidator.isValid(newValue) {
                            showError = true
                            errorMessage = "Invalid FEN notation."
                            return
                        } else {
                            showError = false
                            errorMessage = ""
                        }
                        
                        boardModel.setFEN(newValue)
                    }
                    .onChange(of: boardModel.fen) {
                        fen = boardModel.fen
                    }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Slider(value: $size, in: 200...350, step: 10) {
                Text("Board Size: \(Int(boardModel.size))")
            } minimumValueLabel: {
                Text("200")
            } maximumValueLabel: {
                Text("350")
            }
            .padding(.horizontal)
            
            Text("Board Size: \(Int(size))")
                .font(.caption)
            
            HStack {
                Button {
                    print(FENSerializer().fen(from: boardModel.game.position))
                } label: {
                    Text("Print FEN")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation {
                        boardModel.fen = Self.POSITION
                    }
                } label: {
                    Text("Reset")
                        .padding()
                        .background(resetButtonBackground)
                        .foregroundColor(resetButtonForeground)
                        .fontWeight(.semibold)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(resetButtonForeground.opacity(isResetDisabled ? 0.35 : 0), lineWidth: 1)
                        )
                }
                .disabled(isResetDisabled)
                
                Button {
                    boardModel.hint("d3", for: 1)
                } label: {
                    Text("Hint")
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .buttonStyle(.plain)
            
            Button {
                boardModel.togglePromotionPicker()
            } label: {
                VStack {
                    if boardModel.isPromotionPickerPresented {
                        Text("Hide Promotion Picker")
                    } else {
                        Text("Show Promotion Picker")
                    }
                }
                .padding()
                .background(boardModel.isPromotionPickerPresented ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
        .background {
            GeometryReader { proxy in
                ZStack {
                    TimelineView(.animation) { context in
                        Color.white
                            .scaledToFill()
                            .visualEffect { content, proxy in
                                content
                                    .colorEffect(ShaderLibrary.circlesBackground(
                                        .boundingRect,
                                        .float(backgroundAnimationStartDate.timeIntervalSinceNow),
                                        .color(Color(hue: 0.0, saturation: 0.0, brightness: 0.935)),
                                        .color(Color(hue: 0.0, saturation: 0.0, brightness: 0.890))
                                    ))
                            }
                    }
                    
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.1), location: 0),
                            .init(color: .white.opacity(0.9), location: 0.33)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
    }
}

#Preview {
    ContentView()
}
