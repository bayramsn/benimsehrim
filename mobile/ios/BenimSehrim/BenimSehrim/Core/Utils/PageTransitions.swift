import SwiftUI

// MARK: - Page Transition Modifiers

extension AnyTransition {
    /// Slide transition (default)
    static var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Scale transition
    static var scale: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
    
    /// Shared axis transition (Material Design)
    static var sharedAxis: AnyTransition {
        .asymmetric(
            insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity),
            removal: AnyTransition.move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Bottom sheet transition
    static var bottomSheet: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
    
    /// Fade transition
    static var fade: AnyTransition {
        .opacity
    }
}

// MARK: - Navigation Transition View

struct NavigationTransition<Content: View>: View {
    let content: Content
    let transition: AnyTransition
    let animation: Animation
    
    init(
        transition: AnyTransition = .slide,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.8),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.transition = transition
        self.animation = animation
    }
    
    var body: some View {
        content
            .transition(transition)
            .animation(animation, value: UUID())
    }
}

// MARK: - Page Transition Animations

struct PageTransitionAnimations {
    /// Fast transition (150ms)
    static let fast = Animation.easeInOut(duration: 0.15)
    
    /// Normal transition (300ms)
    static let normal = Animation.easeInOut(duration: 0.3)
    
    /// Slow transition (500ms)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    /// Spring transition
    static let spring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    /// Bouncy spring
    static let bouncySpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0
    )
    
    /// Smooth spring
    static let smoothSpring = Animation.spring(
        response: 0.35,
        dampingFraction: 0.9,
        blendDuration: 0
    )
}

// MARK: - Navigation Stack with Transitions

struct TransitionNavigationStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
        }
        .navigationTransition(.slide)
    }
}

// MARK: - View Extension for Transitions

extension View {
    /// Apply navigation transition
    func navigationTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }
    
    /// Apply smooth animation
    func smoothAnimation(_ animation: Animation = PageTransitionAnimations.spring) -> some View {
        self.animation(animation, value: UUID())
    }
    
    /// Apply scale effect on tap
    func scaleOnTap(scale: CGFloat = 0.95) -> some View {
        self.modifier(ScaleOnTapModifier(scale: scale))
    }
}

// MARK: - Scale On Tap Modifier

struct ScaleOnTapModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - Smooth List Transition

struct SmoothListTransition: ViewModifier {
    @State private var appeared = false
    let index: Int
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    func smoothListTransition(index: Int) -> some View {
        self.modifier(SmoothListTransition(index: index))
    }
}

// MARK: - Hero Animation

struct HeroModifier: ViewModifier {
    let id: String
    @Namespace private var namespace
    
    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(id: id, in: namespace)
    }
}

extension View {
    func hero(id: String) -> some View {
        self.modifier(HeroModifier(id: id))
    }
}

// MARK: - Shimmer Animation

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
