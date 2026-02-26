import SwiftUI

class PrimeGameViewModel: ObservableObject {
    @Published var currentNumber: Int = 0
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var answerState: AnswerState = .none
    @Published var showDialog: Bool = false
    @Published var timeRemaining: Int = 5
    
    private var timer: Timer?
    private var totalAttempts: Int = 0
    
    enum AnswerState {
        case none, correct, wrong
    }
    
    init() {
        generateNewNumber()
        startTimer()
    }
    
    func generateNewNumber() {
        currentNumber = Int.random(in: 2...100)
        answerState = .none
        timeRemaining = 5
    }
    
    func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n == 2 { return true }
        if n % 2 == 0 { return false }
        for i in stride(from: 3, through: Int(Double(n).squareRoot()), by: 2) {
            if n % i == 0 { return false }
        }
        return true
    }
    
    func userSelected(isPrime: Bool) {
        guard answerState == .none else { return }
        let correct = isPrime == self.isPrime(currentNumber)
        answerState = correct ? .correct : .wrong
        if correct { correctCount += 1 } else { wrongCount += 1 }
        totalAttempts += 1
        checkForDialog()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !self.showDialog {
                self.generateNewNumber()
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 1 {
                    self.timeRemaining -= 1
                } else {
                    if self.answerState == .none {
                        self.answerState = .wrong
                        self.wrongCount += 1
                        self.totalAttempts += 1
                        self.checkForDialog()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if !self.showDialog {
                            self.generateNewNumber()
                        }
                    }
                }
            }
        }
    }
    
    func checkForDialog() {
        if totalAttempts % 10 == 0 && totalAttempts > 0 {
            showDialog = true
            timer?.invalidate()
        }
    }
    
    func dismissDialog() {
        showDialog = false
        correctCount = 0
        wrongCount = 0
        totalAttempts = 0
        generateNewNumber()
        startTimer()
    }
}

struct ContentView: View {
    @StateObject private var vm = PrimeGameViewModel()
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Timer circle top right
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        Circle()
                            .trim(from: 0, to: CGFloat(vm.timeRemaining) / 5.0)
                            .stroke(
                                vm.timeRemaining <= 2 ? Color.red : Color.green,
                                lineWidth: 4
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: vm.timeRemaining)
                        Text("\(vm.timeRemaining)")
                            .font(.headline)
                            .foregroundColor(vm.timeRemaining <= 2 ? .red : .primary)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Number
                Text("\(vm.currentNumber)")
                    .font(.system(size: 90, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.teal)
                
                Spacer()
                
                // Prime button
                Button(action: { vm.userSelected(isPrime: true) }) {
                    Text("Prime")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(.teal)
                }
                .disabled(vm.answerState != .none)
                .padding(.bottom, 10)
                
                // Not Prime button
                Button(action: { vm.userSelected(isPrime: false) }) {
                    Text("non Prime")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(.teal)
                }
                .disabled(vm.answerState != .none)
                
                Spacer()
                
                // Tick or Cross
                Group {
                    switch vm.answerState {
                    case .correct:
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.green)
                            .bold()
                    case .wrong:
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red)
                            .bold()
                    case .none:
                        Color.clear
                            .frame(width: 70, height: 70)
                    }
                }
                
                Spacer()
                
                // Score at bottom
                HStack {
                    Text("\(vm.correctCount)")
                        .foregroundColor(.green)
                        .font(.title2)
                        .padding(.leading, 30)
                    Spacer()
                    Text(" \(vm.wrongCount)")
                        .foregroundColor(.red)
                        .font(.title2)
                        .padding(.trailing, 30)
                }
                .padding(.bottom, 20)
            }
        }
        .alert("Results after 10 attempts", isPresented: $vm.showDialog) {
            Button("Continue", action: vm.dismissDialog)
        } message: {
            Text(" Correct: \(vm.correctCount)\n Wrong: \(vm.wrongCount)")
        }
    }
}

#Preview {
    ContentView()
}