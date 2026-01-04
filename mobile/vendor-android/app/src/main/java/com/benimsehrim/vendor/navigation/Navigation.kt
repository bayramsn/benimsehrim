package com.benimsehrim.vendor.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.benimsehrim.vendor.feature.auth.LoginScreen
import com.benimsehrim.vendor.feature.auth.AuthViewModel
import com.benimsehrim.vendor.feature.dashboard.DashboardScreen
import com.benimsehrim.vendor.feature.orders.OrdersScreen
import com.benimsehrim.vendor.feature.orders.OrderDetailScreen
import com.benimsehrim.vendor.feature.products.ProductsScreen
import com.benimsehrim.vendor.feature.products.AddProductScreen
import com.benimsehrim.vendor.feature.campaigns.CampaignsScreen
import com.benimsehrim.vendor.feature.settings.SettingsScreen

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Dashboard : Screen("dashboard")
    object Orders : Screen("orders")
    object OrderDetail : Screen("orders/{orderId}")
    object Products : Screen("products")
    object AddProduct : Screen("products/add")
    object Campaigns : Screen("campaigns")
    object Settings : Screen("settings")
}

@Composable
fun VendorNavigation(authViewModel: AuthViewModel = hiltViewModel()) {
    val navController = rememberNavController()
    val isLoggedIn by authViewModel.isLoggedIn.collectAsState()

    NavHost(
        navController = navController,
        startDestination = if (isLoggedIn) Screen.Dashboard.route else Screen.Login.route
    ) {
        composable(Screen.Login.route) {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Dashboard.route) {
            DashboardScreen(
                onOrdersClick = { navController.navigate(Screen.Orders.route) },
                onProductsClick = { navController.navigate(Screen.Products.route) },
                onCampaignsClick = { navController.navigate(Screen.Campaigns.route) },
                onSettingsClick = { navController.navigate(Screen.Settings.route) }
            )
        }

        composable(Screen.Orders.route) {
            OrdersScreen(
                onBack = { navController.popBackStack() },
                onOrderClick = { orderId ->
                    navController.navigate("orders/$orderId")
                }
            )
        }

        composable(Screen.OrderDetail.route) { backStackEntry ->
            val orderId = backStackEntry.arguments?.getString("orderId") ?: ""
            OrderDetailScreen(
                orderId = orderId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Products.route) {
            ProductsScreen(
                onBack = { navController.popBackStack() },
                onAddProduct = { navController.navigate(Screen.AddProduct.route) }
            )
        }

        composable(Screen.AddProduct.route) {
            AddProductScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Campaigns.route) {
            CampaignsScreen(onBack = { navController.popBackStack() })
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onLogout = {
                    authViewModel.logout()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }
    }
}
