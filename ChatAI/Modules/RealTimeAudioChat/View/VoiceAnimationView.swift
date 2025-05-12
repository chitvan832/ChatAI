import SwiftUI

struct VoiceAnimationView: View {
    
    @Binding var isListening: Bool

    // ViewModels per ring
    @StateObject private var greenVM  = ReactiveCircleViewModel()
    @StateObject private var orangeVM = ReactiveCircleViewModel()
    @StateObject private var blueVM   = ReactiveCircleViewModel()
    @StateObject private var redVM    = ReactiveCircleViewModel()

    var body: some View {
        VStack {
            ZStack {
                ReactiveCircleView(viewModel: greenVM,
                               trimEnd: 1, color: .green, width: 250)
                ReactiveCircleView(viewModel: orangeVM,
                               trimEnd: 1, color: .orange, width: 200)
                ReactiveCircleView(viewModel: blueVM,
                               trimEnd: 1, color: .blue, width: 150)
                ReactiveCircleView(viewModel: redVM,
                               trimEnd: 1, color: .red, width: 100)

                Text("Listening...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(isListening ? 1 : 0.0)
                    .animation(.easeInOut, value: isListening)
            }
            .frame(width: 300, height: 300)
            .onAppear {
                greenVM.configure(baseSpeed: 10, activeSpeed: 50)
                orangeVM.configure(baseSpeed: -12, activeSpeed: -70)
                blueVM.configure(baseSpeed: -8, activeSpeed: -60)
                redVM.configure(baseSpeed: 15, activeSpeed: 80)
            }
            .onChange(of: isListening) { _, newValue in
                [greenVM, orangeVM, blueVM, redVM].forEach { model in
                    model.isListening = newValue
                }
            }
        }
    }
}
