import SwiftUI

struct RootView: View {
    @State private var splashOpacity = 1.0

    var body: some View {
        ZStack {
            ContentView()
            SplashView {
                withAnimation(.easeInOut(duration: 0.7)) {
                    splashOpacity = 0.0
                }
            }
            .opacity(splashOpacity)
            .allowsHitTesting(splashOpacity > 0.01)
        }
    }
}

struct SplashView: View {
    @State private var imageOpacity = 0.0

    var onFinished: () -> Void

    // 六条随机 slogan，文艺简短
    private let slogans = [
        "光阴流过，你留下了什么",
        "随手记下，才是真正拥有",
        "每一刻，都值得被记住",
        "花开须折，此刻须记",
        "生活流过，留痕才是永恒",
        "随手一记，时光不散"
    ]
    private let slogan: String

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        self.slogan = slogans.randomElement()!
    }

    var body: some View {
        ZStack {
            // 底色，第一帧就不透明
            Color(red: 0.94, green: 0.95, blue: 0.99)
                .ignoresSafeArea()

            // 樱花背景图
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(imageOpacity)

            // 文字层（随机 slogan，马善政字体）
            VStack(spacing: 16) {
                Spacer()

                Text("随 手 记")
                    .font(.custom("MaShanZheng-Regular", size: 52))
                    .tracking(8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.35, blue: 0.87),
                                Color(red: 0.55, green: 0.22, blue: 0.83)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(red: 0.70, green: 0.75, blue: 0.92).opacity(0.6))
                        .frame(width: 40, height: 0.5)
                    Rectangle()
                        .fill(Color(red: 0.70, green: 0.75, blue: 0.92).opacity(0.6))
                        .frame(width: 40, height: 0.5)
                }

                Text(slogan)
                    .font(.custom("MaShanZheng-Regular", size: 15))
                    .tracking(2.5)
                    .foregroundStyle(Color(red: 0.45, green: 0.50, blue: 0.70))

                Spacer()

                Text("· 随手记录  留住此刻 ·")
                    .font(.custom("MaShanZheng-Regular", size: 13))
                    .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.78).opacity(0.7))
                    .padding(.bottom, 60)
            }
            .opacity(imageOpacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                imageOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
    }
}
