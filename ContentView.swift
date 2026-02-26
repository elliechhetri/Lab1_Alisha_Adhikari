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
    
    // MARK: - Generate New Number
    func generateNewNumber() {
        currentNumber = Int.random(in: 2...100)
        answerState = .none
        timeRemaining = 5
        startTimer() // always restart timer with new number
    }
    
    // MARK: - Prime Check
    func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n == 2 { return true }
        if n % 2 == 0 { return false }
        for i in stride(from: 3, through: Int(Double(n).squareRoot()), by: 2) {
            if n % i == 0 { return false }
        }
        return true
    }
    
    // MARK: - User Tapped Answer
    func userSelected(isPrime: Bool) {
        guard answerState == .none else { return }
        
        // Stop timer immediately when user answers
        timer?.invalidate()
        timer = nil
        
        let correct = isPrime == self.isPrime(currentNumber)
        answerState = correct ? .correct : .wrong
        if correct {
            correctCount += 1
        } else {
            wrongCount += 1
        }
        totalAttempts += 1
        
        if checkForDialog() { return }
        
        // Move to next number after 1 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generateNewNumber()
        }
    }
    
    // MARK: - Timer
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.timeRemaining > 1 {
                    self.timeRemaining -= 1
                } else {
                    // Time's up
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    if self.answerState == .none {
                        self.answerState = .wrong
                        self.wrongCount += 1
                        self.totalAttempts += 1
                        if self.checkForDialog() { return }
                    }
                    
                    // Move to next after short pause
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.generateNewNumber()
                    }
                }
            }
        }
    }
    
    // MARK: - Check Dialog (returns true if dialog shown)
    @discardableResult
    func checkForDialog() -> Bool {
        if totalAttempts % 10 == 0 && totalAttempts > 0 {
            timer?.invalidate()
            timer = nil
            showDialog = true
            return true
        }
        return false
    }
    
    // MARK: - Dismiss Dialog & Reset
    func dismissDialog() {
        showDialog = false
        correctCount = 0
        wrongCount = 0
        totalAttempts = 0
        generateNewNumber()
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var vm = PrimeGameViewModel()
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: Timer Circle (top right)
                HStack {
                    Spacer()
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                            .frame(width: 55, height: 55)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: CGFloat(vm.timeRemaining) / 5.0)
                            .stroke(
                                vm.timeRemaining <= 2 ? Color.red : Color.green,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 55, height: 55)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: vm.timeRemaining)
                        
                        // Number inside circle
                        Text("\(vm.timeRemaining)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(vm.timeRemaining <= 2 ? .red : .gray)
                    }
                    .padding()
                }
                
                Spacer()
                
                // MARK: Random Number
                Text("\(vm.currentNumber)")
                    .font(.system(size: 90, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.teal)
                    .transition(.opacity)
                    .id(vm.currentNumber) // triggers animation on change
                    .animation(.easeIn(duration: 0.3), value: vm.currentNumber)
                
                Spacer()
                
                // MARK: Prime Button
                Button(action: { vm.userSelected(isPrime: true) }) {
                    Text("Prime")
                        .font(.system(size: 38, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(vm.answerState == .none ? .teal : .gray)
                }
                .disabled(vm.answerState != .none)
                .padding(.bottom, 16)
                
                // MARK: Non Prime Button
                Button(action: { vm.userSelected(isPrime: false) }) {
                    Text("non Prime")
                        .font(.system(size: 38, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(vm.answerState == .none ? .teal : .gray)
                }
                .disabled(vm.answerState != .none)
                
                Spacer()
                
                // MARK: Tick or Cross Feedback
                ZStack {
                    Color.clear.frame(width: 80, height: 80)
                    
                    switch vm.answerState {
                    case .correct:
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                            .transition(.scale)
                    case .wrong:
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                            .transition(.scale)
                    case .none:
                        EmptyView()
                    }
                }
                .animation(.spring(), value: vm.answerState)
                
                Spacer()
                
                // MARK: Score at Bottom
                HStack {
                    Text("\(vm.correctCount)")
                        .foregroundColor(.green)
                        .font(.system(size: 22, weight: .semibold))
                        .padding(.leading, 30)
                    Spacer()
                    Text("\(vm.wrongCount)")
                        .foregroundColor(.red)
                        .font(.system(size: 22, weight: .semibold))
                        .padding(.trailing, 30)
                }
                .padding(.bottom, 25)
            }
        }
        // MARK: Dialog after 10 attempts
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