package com.benimsehrim.app.ui.navigation

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.IntOffset
import androidx.navigation.NavBackStackEntry

@OptIn(ExperimentalAnimationApi::class)

/**
 * Smooth page transition animations
 */
object PageTransitions {
    
    /**
     * Slide transition (default)
     */
    @OptIn(ExperimentalAnimationApi::class)
    fun slideTransition(): AnimatedContentTransitionScope<NavBackStackEntry>.() -> ContentTransform {
        return {
            slideIntoContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(300, easing = FastOutSlowInEasing)
            ) + fadeIn(animationSpec = tween(300)) with
            slideOutOfContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(300, easing = FastOutSlowInEasing)
            ) + fadeOut(animationSpec = tween(300))
        }
    }
    
    /**
     * Fade transition
     */
    fun fadeTransition(): AnimatedContentTransitionScope<NavBackStackEntry>.() -> ContentTransform {
        return {
            fadeIn(
                animationSpec = tween(300, easing = LinearEasing)
            ) with fadeOut(
                animationSpec = tween(300, easing = LinearEasing)
            )
        }
    }
    
    /**
     * Scale + Fade transition
     */
    fun scaleTransition(): AnimatedContentTransitionScope<NavBackStackEntry>.() -> ContentTransform {
        return {
            fadeIn(
                animationSpec = tween(300)
            ) + scaleIn(
                initialScale = 0.95f,
                animationSpec = tween(300, easing = FastOutSlowInEasing)
            ) with fadeOut(
                animationSpec = tween(300)
            ) + scaleOut(
                targetScale = 0.95f,
                animationSpec = tween(300, easing = FastOutSlowInEasing)
            )
        }
    }
    
    /**
     * Shared axis transition (Material Design)
     */
    @OptIn(ExperimentalAnimationApi::class)
    fun sharedAxisTransition(): AnimatedContentTransitionScope<NavBackStackEntry>.() -> ContentTransform {
        return {
            slideIntoContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Up,
                animationSpec = tween(300, easing = FastOutSlowInEasing),
                initialOffset = { it / 4 }
            ) + fadeIn(
                animationSpec = tween(300)
            ) with slideOutOfContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Up,
                animationSpec = tween(300, easing = FastOutSlowInEasing),
                targetOffset = { -it / 4 }
            ) + fadeOut(
                animationSpec = tween(300)
            )
        }
    }
    
    /**
     * Bottom sheet transition
     */
    @OptIn(ExperimentalAnimationApi::class)
    fun bottomSheetTransition(): AnimatedContentTransitionScope<NavBackStackEntry>.() -> ContentTransform {
        return {
            slideIntoContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Up,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                )
            ) + fadeIn() with slideOutOfContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Down,
                animationSpec = tween(300)
            ) + fadeOut()
        }
    }
}

/**
 * Custom transition specs
 */
object TransitionSpecs {
    // Fast transition (150ms)
    val fast = tween<Float>(
        durationMillis = 150,
        easing = FastOutSlowInEasing
    )
    
    // Normal transition (300ms)
    val normal = tween<Float>(
        durationMillis = 300,
        easing = FastOutSlowInEasing
    )
    
    // Slow transition (500ms)
    val slow = tween<Float>(
        durationMillis = 500,
        easing = FastOutSlowInEasing
    )
    
    // Spring transition
    val spring = spring<Float>(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessLow
    )
    
    // Bouncy spring
    val bouncySpring = spring<Float>(
        dampingRatio = Spring.DampingRatioLowBouncy,
        stiffness = Spring.StiffnessMedium
    )
}

/**
 * Easing functions
 */
object Easings {
    val fastOutSlowIn = FastOutSlowInEasing
    val linearOutSlowIn = LinearOutSlowInEasing
    val fastOutLinearIn = FastOutLinearInEasing
    val linear = LinearEasing
}
