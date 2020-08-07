//
//  EmojiMemoryGameView.swift
//  Memorize
//
//  Created by CS193P Instructor on 04/06/2020.
//  Copyright © 2020 cs193p instructor. All rights reserved.
//

import SwiftUI

struct EmojiMemoryGameView: View {
    @ObservedObject var viewModel: EmojiMemoryGame
    
    var body: some View {
        VStack {
            Grid (viewModel.cards) { card in
                CardView(card: card).onTapGesture {
                    withAnimation (.linear(duration:0.75)) {
                        self.viewModel.choose(card: card)
                    }
                }
                .padding(5)
            }
            .padding()
            .foregroundColor(Color.orange)
            Button(action: {
                withAnimation (.easeInOut) {
                    self.viewModel.resetGame()
                }
            }, label: {Text("New Game")})
        }
    }
}

struct CardView: View {
    var card: MemoryGame<String>.Card
    
    var body: some View {
        GeometryReader { geometry in
            self.body(for: geometry.size)
        }
    }
    
    @State private var animatedBonusRemaining: Double = 0
    
    private func startBonusTimeAnimation() {
        animatedBonusRemaining = card.bonusRemaining
        
        withAnimation(.linear(duration:card.bonusTimeRemaining)) {
            animatedBonusRemaining = 0
        }
    }
    
    @ViewBuilder
    private func body (for size: CGSize) -> some View {
        if card.isFaceUp || !card.isMatched {
            ZStack {
                Group {
                    if card.isConsumingBonusTime {
                        Pie(startAngle: Angle.degrees(0 - 90),
                            endAngle: Angle.degrees(-animatedBonusRemaining*360 - 90),
                            clockwise: true)
                            .onAppear(){self.startBonusTimeAnimation()}
                    } else {
                        Pie(startAngle: Angle.degrees(0 - 90),
                            endAngle: Angle.degrees(-card.bonusRemaining * 360 - 90),
                            clockwise: true)
                    }
                }
                .padding(5).opacity(0.4)
                .transition(AnyTransition.identity)
                Text(card.content)
                    .font(Font.system(size: fontSize(for: size)))
                    .rotationEffect(Angle.degrees(card.isMatched ? 360 :0))
                    .animation(
                        card.isMatched
                            ?
                                Animation.linear(duration: 1).repeatForever(autoreverses: false)
                            :
                            .default)
            }
            .cardify(isFaceUp: card.isFaceUp)
            .transition(AnyTransition.scale)
        }
    }
    
     // MARK:  Drawing Constants
    
    private func fontSize(for size:CGSize) -> CGFloat {
         min(size.width, size.height) *  0.65
    }
}















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = EmojiMemoryGame()
        game.choose(card: game.cards[0])
        return EmojiMemoryGameView(viewModel: game)
    }
}
