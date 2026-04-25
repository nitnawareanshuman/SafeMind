import SwiftUI

struct BlurBackground: View {
    
    @State private var move = false
    
    var body: some View {
        ZStack {
            
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 300)
                .blur(radius: 120)
                .offset(x: move ? -80 : -150, y: move ? -220 : -170)
            
            Circle()
                .fill(Color.green.opacity(0.6))
                .frame(width: 300)
                .blur(radius: 120)
                .offset(x: move ? 170 : 120, y: move ? -120 : -180)
            
            Circle()
                .fill(Color.pink.opacity(0.5))
                .frame(width: 350)
                .blur(radius: 150)
                .offset(x: move ? 20 : -20, y: move ? 280 : 230)
            
            Circle()
                .fill(Color.yellow.opacity(0.5))
                .frame(width: 350)
                .blur(radius: 150)
                .offset(x: move ? -40 : 40, y: move ? -280 : -220)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
            ) {
                move.toggle()
            }
        }
    }
}

#Preview {
    BlurBackground()
}
