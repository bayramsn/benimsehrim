package com.benimsehrim.driver.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.benimsehrim.driver.feature.auth.LoginScreen
import com.benimsehrim.driver.feature.home.DriverHomeScreen
import com.benimsehrim.driver.feature.earnings.EarningsScreen
import com.benimsehrim.driver.feature.navigation.NavigationScreen

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Home : Screen("home")
    object Navigation : Screen("navigation/{taskId}") {
        fun createRoute(taskId: String) = "navigation/$taskId"
    }
    object Earnings : Screen("earnings")
}

@Composable
fun DriverNavigation(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Home.route) {
            DriverHomeScreen(
                onNavigateToTask = { taskId ->
                    navController.navigate(Screen.Navigation.createRoute(taskId))
                },
                onNavigateToEarnings = {
                    navController.navigate(Screen.Earnings.route)
                }
            )
        }

        composable(Screen.Navigation.route) { backStackEntry ->
            val taskId = backStackEntry.arguments?.getString("taskId") ?: ""
            NavigationScreen(
                taskId = taskId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Earnings.route) {
            EarningsScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}
