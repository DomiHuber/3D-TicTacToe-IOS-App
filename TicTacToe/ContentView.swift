//
//  ContentView.swift
//  TicTacToe
//
//  Created by Dominic Huber on 13.02.22.
//

import SwiftUI

enum SquareStatus {
    case empty
    case X
    case O
    case active
    case draw
}

enum Modus {
    case pvsp
    case pvsc
}


class Square : ObservableObject {
    @Published var squareStatus : SquareStatus
    
    init(status : SquareStatus) {
        self.squareStatus = status
    }
}

class TicTacToeModel : ObservableObject, NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TicTacToeModel(bigboard: bigboard, board: board, player: self.player, copy: true)
        return copy
    }
    @Published var board = [[Square]]()
    @Published var bigboard = [Square]()
    @Published var player: SquareStatus = .X
    @Published var difficulty: Int = 2
    @Published var gameHistory: [([[Square]], [Square])] = []
    var values = Array(repeating: 0, count: 9)

    
    init(bigboard: [Square], board: [[Square]], player: SquareStatus, copy: Bool) {
        if copy {
            for i in 0..<9 {
                var sublist = [Square]()
                for j in 0..<9 {
                    sublist.append(Square(status: board[i][j].squareStatus))
                }
                self.board.append(sublist)
                self.bigboard.append(Square(status: bigboard[i].squareStatus))
                self.player = player
            }
        }
        else {
            for _ in 0..<9 {
                var sublist = [Square]()
                for _ in 0..<9 {
                    sublist.append(Square(status: .empty))
                }
                self.board.append(sublist)
                self.bigboard.append(Square(status: .active))
            }
        }
    }
    
    func setDifficulty(difficulty: Int) {
        self.difficulty = difficulty
    }
    
    func evaluate(board: [[Square]], bigboard: [Square]) -> Int {
        var score: Int = 0
        for i in 0..<9 {
            self.values[i] = 0
        }
        score += 100 * winnerEval(smallboard: bigboard, bigboard: true)
        for i in 0..<9 {
            score += self.values[i] * winnerEval(smallboard: board[i], bigboard: false)
        }
        return score
    }
    
    func minimax(tictactoe: TicTacToeModel, alpha: Int, beta: Int, player: SquareStatus, depth: Int) -> Int {
        if depth == 0 || self.result(smallboard: tictactoe.bigboard).1 {
            if depth == 0 {
                return self.evaluate(board: tictactoe.board, bigboard: tictactoe.bigboard)
            }
            else {
                let result = self.result(smallboard: tictactoe.bigboard).0
                if result == .X {
                    return 10000
                }
                else if result == .O {
                    return -10000
                }
                else {
                    return 0
                }
            }
        }
        if player == .X {
            var maxeval = -10001
            var alpha = alpha
            for i in 0..<9 {
                if tictactoe.bigboard[i].squareStatus == .active {
                    for j in 0..<9 {
                        if tictactoe.board[i][j].squareStatus == .empty {
                            let copy = tictactoe.copy() as! TicTacToeModel
                            copy.makeMove(bigindex: i, index: j)
                            let eval = minimax(tictactoe: copy, alpha: alpha, beta: beta, player: .O, depth: depth - 1)
                            maxeval = eval > maxeval ? eval : maxeval
                            alpha = eval > alpha ? eval : alpha
                            if beta <= alpha {
                                return maxeval
                            }
                        }
                    }
                }
            }
            return maxeval
        }
        else {
            var mineval = 10001
            var beta = beta
            for i in 0..<9 {
                if tictactoe.bigboard[i].squareStatus == .active {
                    for j in 0..<9 {
                        if tictactoe.board[i][j].squareStatus == .empty {
                            let copy = tictactoe.copy() as! TicTacToeModel
                            copy.makeMove(bigindex: i, index: j)
                            let eval = minimax(tictactoe: copy, alpha: alpha, beta: beta, player: .X, depth: depth - 1)
                            mineval = eval < mineval ? eval : mineval
                            beta = eval < beta ? eval : beta
                            if beta <= alpha {
                                return mineval
                            }
                        }
                    }
                }
            }
            return mineval
        }
    }

    func moveAI(depth: Int) {
        var bi: Int = 9
        var bj: Int = 9
        
        if self.player == .X {
            var maxeval = -10001
            for i in 0..<9 {
                if self.bigboard[i].squareStatus == .active {
                    for j in 0..<9 {
                        if self.board[i][j].squareStatus == .empty {
                            let copy = self.copy() as! TicTacToeModel
                            copy.makeMove(bigindex: i, index: j)
                            let eval = minimax(tictactoe: copy, alpha: -10001, beta: 10000, player: .O, depth: depth - 1)
                            if eval > maxeval {
                                maxeval = eval
                                bi = i
                                bj = j
                            }
                        }
                    }
                }
            }
            self.makeMove(bigindex: bi, index: bj)
        }
        else {
            var mineval = 10001
            for i in 0..<9 {
                if self.bigboard[i].squareStatus == .active {
                    for j in 0..<9 {
                        if self.board[i][j].squareStatus == .empty {
                            let copy = self.copy() as! TicTacToeModel
                            copy.makeMove(bigindex: i, index: j)
                            let eval = minimax(tictactoe: copy, alpha: -10001, beta: 10000, player: .X, depth: depth - 1)
                            if eval < mineval {
                                mineval = eval
                                bi = i
                                bj = j
                            }
                        }
                    }
                }
            }
            self.makeMove(bigindex: bi, index: bj)
        }
    }
        
    func result(smallboard: [Square]) -> (SquareStatus, Bool) {
        if winner(smallboard: smallboard) != .empty {
            return (winner(smallboard: smallboard), true)
        }
        else {
            for i in 0..<9 {
                if smallboard[i].squareStatus == .empty || smallboard[i].squareStatus == .active {
                    return (.empty, false)
                }
            }
            return (.draw, true)
        }
    }
    
    private func winner(smallboard: [Square]) -> SquareStatus {
        if let check = self.checkIndexes(smallboard: smallboard, indexes: [0, 1, 2]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [3, 4, 5]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [6, 7, 8]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [0, 3, 6]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [1, 4, 7]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [2, 5, 8]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [0, 4, 8]) {
            return check
        }
        else if let check = self.checkIndexes(smallboard: smallboard, indexes: [2, 4, 6]) {
            return check
        }
        return .empty
    }
    
    private func checkIndexes(smallboard: [Square], indexes: [Int]) -> SquareStatus? {
        var xCounter: Int = 0
        var oCounter: Int = 0
        for index in indexes {
            let square = smallboard[index]
            if square.squareStatus == .X {
                xCounter += 1
            }
            else if square.squareStatus == .O {
                oCounter += 1
            }
        }
        if xCounter == 3 {
            return .X
        }
        else if oCounter == 3 {
            return .O
        }
        return nil
    }
    
    private func winnerEval(smallboard: [Square], bigboard: Bool) -> Int {
        var score: Int = 0
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [0, 1, 2], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [3, 4, 5], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [6, 7, 8], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [0, 3, 6], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [1, 4, 7], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [2, 5, 8], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [0, 4, 8], bigboard: bigboard)
        score += self.checkIndexesEval(smallboard: smallboard, indexes: [2, 4, 6], bigboard: bigboard)
        return score
        
    }
    
    private func checkIndexesEval(smallboard: [Square], indexes: [Int], bigboard: Bool) -> Int {
        var xCounter: Int = 0
        var oCounter: Int = 0
        var draw: Bool = false
        for index in indexes {
            let square = smallboard[index]
            if square.squareStatus == .X {
                xCounter += 1
            }
            else if square.squareStatus == .O {
                oCounter += 1
            }
            else if square.squareStatus == .draw {
                draw = true
            }
        }
        if !(xCounter != 0 && oCounter != 0 || draw) {
            if bigboard {
                for i in indexes {
                    self.values[i] += xCounter + oCounter + 1
                }
            }
            return xCounter - oCounter
        }
        return 0
    }
    
    func makeMove(bigindex: Int, index: Int) {
        self.board[bigindex][index].squareStatus = self.player
        let result = self.result(smallboard: self.board[bigindex])
        if result.1 {
            self.bigboard[bigindex].squareStatus = result.0
        }
        for i in 0..<9 {
            if self.bigboard[i].squareStatus == .active {
                self.bigboard[i].squareStatus = .empty
            }
        }
        if self.bigboard[index].squareStatus == .empty {
            self.bigboard[index].squareStatus = .active
        }
        else if self.bigboard[bigindex].squareStatus == .empty {
            self.bigboard[bigindex].squareStatus =  .active
        }
        else {
            for i in 0..<9 {
                if self.bigboard[i].squareStatus == .empty {
                    self.bigboard[i].squareStatus = .active
                }
            }
        }
        if self.player == .X {
            self.player = .O
        }
        else {
            self.player = .X
        }
    }
    
    func undo() {
        if self.gameHistory.count > 0 {
            let last = self.gameHistory.removeLast()
            self.board = last.0
            self.bigboard = last.1
            if self.difficulty == 0 {
                if self.player == .X {
                    self.player = .O
                }
                else {
                    self.player = .X
                }
            }
        }
    }
}

struct SquareView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var data : Square
    var action: () -> Void
    var opacity: CGFloat
    let size = UIScreen.main.bounds.width * 0.08
    var body: some View {
        Button(action: {
            self.action()
        }, label: {
            Text(self.data.squareStatus == .X ? "X" : self.data.squareStatus == .O ? "O" : " ")
                .font(.system(size: self.size * 4 / 5))
                .bold()
                .foregroundColor(self.colorScheme == .dark ? self.data.squareStatus == .X ? .blue : .red : .black)
                .frame(width: self.size, height: self.size, alignment: .center)
                .background(Color.gray.opacity(self.opacity).cornerRadius(self.size / 5))
                
        })
    }
}


struct Game: View {
    var difficulty: Int
    var computer: SquareStatus
    @Environment(\.colorScheme) var colorScheme
    @State var firstmove: Bool = true
    @ObservedObject var ticTacToeModel = TicTacToeModel(bigboard: [], board: [[]], player: .X, copy: false)
    @State var gameover: Bool = false
    
    
    init(computer: SquareStatus, difficulty: Int) {
        self.computer = computer
        self.difficulty = difficulty
        self.ticTacToeModel.setDifficulty(difficulty: difficulty)
    }
    
    let width = UIScreen.main.bounds.width
    
    
    func resetGame() {
        for i in 0..<9 {
            for j in 0..<9 {
                self.ticTacToeModel.board[i][j].squareStatus = .empty
            }
            self.ticTacToeModel.bigboard[i].squareStatus = .active
        }
        self.gameover = false
        self.ticTacToeModel.player = .X
        self.firstmove = true
    }
    func buttonAction(bigindex: Int, index: Int) {
        if ticTacToeModel.bigboard[bigindex].squareStatus == .active && ticTacToeModel.board[bigindex][index].squareStatus == .empty && !ticTacToeModel.result(smallboard: ticTacToeModel.bigboard).1 {
            let copy = self.ticTacToeModel.copy() as! TicTacToeModel
            self.ticTacToeModel.gameHistory.append((copy.board, copy.bigboard))
            self.ticTacToeModel.makeMove(bigindex: bigindex, index: index)
            self.gameover = self.ticTacToeModel.result(smallboard: self.ticTacToeModel.bigboard).1
        }
    }
    
    func miniBoardView(bigindex: Int) -> some View {
        let width = UIScreen.main.bounds.width
        if self.ticTacToeModel.player == self.computer {
            if self.firstmove && self.computer == .X {
                self.ticTacToeModel.makeMove(bigindex: 4, index: 4)
                DispatchQueue.main.async {
                    self.firstmove = false
                }
            }
            else {
                self.ticTacToeModel.moveAI(depth: self.difficulty)
                DispatchQueue.main.async {
                    self.gameover = self.ticTacToeModel.result(smallboard: self.ticTacToeModel.bigboard).1
                }
            }
        }
        return ZStack {
            if self.colorScheme == .dark {
                Color.black.frame(width: 0.305 * width, height: 0.305 * width)
            }
            else {
                Color.white.frame(width: 0.305 * width, height: 0.305 * width)
            }
            VStack(spacing: width / 100) {
                ForEach(0..<3, content: {
                    row in
                    HStack(spacing: width / 100) {
                        ForEach(0..<3, content: {
                            column in
                            let index = row * 3 + column
                            SquareView(data: ticTacToeModel.board[bigindex][index], action: {self.buttonAction(bigindex: bigindex, index: index)}, opacity: ticTacToeModel.bigboard[bigindex].squareStatus == .active ? 0.5 : 0.3)
                        })
                    }
                })
            }
        }
    }
    
    func wonMiniBoardView(bigindex: Int) -> some View {
        let width = UIScreen.main.bounds.width
        var fontsize: CGFloat
        if (ticTacToeModel.bigboard[bigindex].squareStatus == .draw) {
            fontsize = 0.244 / 3 * UIScreen.main.bounds.width
        }
        else {
            fontsize = 0.244 * UIScreen.main.bounds.width
        }
        if self.ticTacToeModel.player == self.computer {
            self.ticTacToeModel.moveAI(depth: self.difficulty)
            DispatchQueue.main.async {
                self.gameover = self.ticTacToeModel.result(smallboard: self.ticTacToeModel.bigboard).1
            }
        }
        return ZStack {
            if self.colorScheme == .dark {
                Color.black.frame(width: 0.305 * width, height: 0.305 * width)
            }
            else {
                Color.white.frame(width: 0.305 * width, height: 0.305 * width)
            }
            Text(ticTacToeModel.bigboard[bigindex].squareStatus == .X ? "X" : ticTacToeModel.bigboard[bigindex].squareStatus == .O ? "O" : "Draw!")
                .font(.system(size: fontsize))
                .bold()
                .
            foregroundColor(self.colorScheme == .dark ? ticTacToeModel.bigboard[bigindex].squareStatus == .X ? .blue : .red : .black)
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text(self.computer == .empty ? "Player vs. Player" : self.computer == .X ? "Computer vs. Player" : "Player vs. Computer")
                    .font(.system(size: 30, weight: .bold))
                if self.computer != .empty {
                    Text(self.difficulty == 1 ? "Super easy" : self.difficulty == 2 ? "Easy" : self.difficulty == 3 ? "Medium" : self.difficulty == 4 ? "Hard" : "Extreme")
                        .font(.system(size: 25, weight: Font.Weight.regular))
                }
                Spacer()
                Text(self.ticTacToeModel.player == .X ? "It is X's turn" : "It is O's turn")
                    .font(.system(size: 25, weight: .bold))
                ZStack {
                    if self.colorScheme == .dark {
                        Color.indigo.frame(width: 0.9 * width, height: 0.9 * width)
                    }
                    else {
                        Color.black.frame(width: 0.9 * width, height: 0.9 * width)
                    }
                    VStack(spacing: width * 0.015) {
                        ForEach(0..<3, content: {
                            bigrow in
                            HStack(spacing: width * 0.015
                            ) {
                                ForEach(0..<3, content: {
                                    bigcolumn in
                                    let bigindex = 3 * bigrow + bigcolumn
                                    if (ticTacToeModel.bigboard[bigindex].squareStatus == .empty || ticTacToeModel.bigboard[bigindex].squareStatus == .active) {
                                        self.miniBoardView(bigindex: bigindex)
                                    }
                                    else {
                                        self.wonMiniBoardView(bigindex: bigindex)
                                    }
                                })
                            }
                        })
                    }
                }
                Spacer()
                HStack {
                    Button("Reset", action: {self.resetGame()}).padding()
                    Spacer()
                    Button("Undo", action: {self.ticTacToeModel.undo()}).padding()
                }
            }
            Spacer()
        }.alert(isPresented: self.$gameover, content: {Alert(title: Text("Game over"), message: Text(self.ticTacToeModel.result(smallboard: self.ticTacToeModel.bigboard).0 == .X ? "X won!" : self.ticTacToeModel.result(smallboard: self.ticTacToeModel.bigboard).0 == .O ? "O won!" : "Draw!"), primaryButton: Alert.Button.default(Text("Cancel")), secondaryButton: Alert.Button.destructive(Text("Reset"), action: {self.resetGame()}))})
    }
}


struct MainMenu: View {
    let width = UIScreen.main.bounds.width * 3 / 4
    let height = UIScreen.main.bounds.height / 8
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: Game(computer: .empty, difficulty: 0)) {
                    ZStack {
                        Color.gray.frame(width: width, height: height, alignment: .center)
                            .cornerRadius(width)
                            .opacity(0.3)
                        Text("Player vs. Player")
                    }.navigationTitle(Text("Menu"))
                }
                NavigationLink(destination: DifficultyMenu(computer: .O)) {
                    ZStack {
                        Color.gray.frame(width: width, height: height, alignment: .center)
                            .cornerRadius(width)
                            .opacity(0.3)
                        Text("Player vs. Computer")
                    }.navigationTitle(Text("Menu"))
                }
                NavigationLink(destination: DifficultyMenu(computer: .X)) {
                    ZStack {
                        Color.gray.frame(width: width, height: height, alignment: .center)
                            .cornerRadius(width)
                            .opacity(0.3)
                        Text("Computer vs. Player")
                    }.navigationTitle(Text("Menu"))
                }
            }
        }
    }
}

struct DifficultyMenu: View {
    let width = UIScreen.main.bounds.width * 3 / 4
    let height = UIScreen.main.bounds.height / 10
    var computer: SquareStatus
    
    init(computer: SquareStatus) {
        self.computer = computer
    }
    var body: some View {
        VStack {
            NavigationLink(destination: Game(computer: self.computer, difficulty: 1)) {
                ZStack {
                    Color.gray.frame(width: width, height: height, alignment: .center)
                        .cornerRadius(width)
                        .opacity(0.3)
                    Text("Super easy")
                }.navigationTitle(Text("Difficulty"))
            }
            NavigationLink(destination: Game(computer: self.computer, difficulty: 2)) {
                ZStack {
                    Color.gray.frame(width: width, height: height, alignment: .center)
                        .cornerRadius(width)
                        .opacity(0.3)
                    Text("Easy")
                }.navigationTitle(Text("Difficulty"))
            }
            NavigationLink(destination: Game(computer: self.computer, difficulty: 3)) {
                ZStack {
                    Color.gray.frame(width: width, height: height, alignment: .center)
                        .cornerRadius(width)
                        .opacity(0.3)
                    Text("Medium")
                }.navigationTitle(Text("Difficulty"))
            }
            NavigationLink(destination: Game(computer: self.computer, difficulty: 4)) {
                ZStack {
                    Color.gray.frame(width: width, height: height, alignment: .center)
                        .cornerRadius(width)
                        .opacity(0.3)
                    Text("Hard")
                }.navigationTitle(Text("Difficulty"))
            }
            NavigationLink(destination: Game(computer: self.computer, difficulty: 5)) {
                ZStack {
                    Color.gray.frame(width: width, height: height, alignment: .center)
                        .cornerRadius(width)
                        .opacity(0.3)
                    Text("Extreme")
                }.navigationTitle(Text("Difficulty"))
            }
        }
    }
}


struct Game_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
            .previewDevice("iPad Pro (9.7-inch")
    }
}
