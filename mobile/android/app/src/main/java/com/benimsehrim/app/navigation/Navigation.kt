package com.benimsehrim.app.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.benimsehrim.app.core.auth.AuthViewModel
import com.benimsehrim.app.feature.auth.LoginScreen
import com.benimsehrim.app.feature.auth.OtpScreen
import com.benimsehrim.app.feature.auth.RegisterScreen
import com.benimsehrim.app.feature.courier.CourierScreen
import com.benimsehrim.app.feature.courier.CallCourierScreen
import com.benimsehrim.app.feature.home.HomeScreen
import com.benimsehrim.app.feature.stores.CreateStoreScreen
import com.benimsehrim.app.feature.stores.StoreDetailScreen
import com.benimsehrim.app.feature.stores.StoresScreen
import com.benimsehrim.app.feature.cart.CartScreen
import com.benimsehrim.app.feature.checkout.CheckoutScreen
import com.benimsehrim.app.feature.checkout.OrderSuccessScreen
import com.benimsehrim.app.feature.orders.OrdersScreen
import com.benimsehrim.app.feature.orders.OrderDetailScreen
import com.benimsehrim.app.feature.taxi.TaxiScreen
import com.benimsehrim.app.feature.taxi.RideDetailScreen
import com.benimsehrim.app.feature.profile.ProfileScreen
import com.benimsehrim.app.feature.profile.AddressesScreen
import com.benimsehrim.app.feature.chat.ChatScreen
import com.benimsehrim.app.feature.home.FavoritesScreen
import com.benimsehrim.app.feature.wallet.WalletScreen
import com.benimsehrim.app.feature.admin.AdminDashboardScreen
import com.benimsehrim.app.feature.vendor.VendorDashboardScreen
import com.benimsehrim.app.feature.driver.DriverDashboardScreen

sealed class Screen(val route: String) {
    // Auth
    object Login : Screen("login")
    object Otp : Screen("otp/{phone}") {
        fun createRoute(phone: String) = "otp/$phone"
    }
    object Register : Screen("register/{phone}") {
        fun createRoute(phone: String) = "register/$phone"
    }
    
    // Main
    object Home : Screen("home")
    object Stores : Screen("stores?categoryId={categoryId}") {
        fun createRoute(categoryId: String? = null) = "stores?categoryId=${categoryId ?: ""}"
    }
    object StoreDetail : Screen("store/{storeId}") {
        fun createRoute(storeId: String) = "store/$storeId"
    }
    object CreateStore : Screen("create_store")

    object Cart : Screen("cart")
    object Checkout : Screen("checkout")
    object OrderSuccess : Screen("order_success")
    
    // Orders
    object Orders : Screen("orders")
    object OrderDetail : Screen("order/{orderId}") {
        fun createRoute(orderId: String) = "order/$orderId"
    }
    
    // Taxi
    object Taxi : Screen("taxi")
    object RideDetail : Screen("ride/{rideId}") {
        fun createRoute(rideId: String) = "ride/$rideId"
    }
    
    // Courier
    object Courier : Screen("courier")
    object CallCourier : Screen("courier_call")
    
    // Profile
    object Profile : Screen("profile")
    object Addresses : Screen("addresses")
    object Wallet : Screen("wallet")
    object Favorites : Screen("favorites")
    
    // Admin
    object Admin : Screen("admin")
    
    // Vendor
    object VendorDashboard : Screen("vendor_dashboard")

    // Driver
    object DriverDashboard : Screen("driver_dashboard")
    
    // Chat
    object Chat : Screen("chat/{chatId}") {
        fun createRoute(chatId: String) = "chat/$chatId"
    }
}

@Composable
fun BenimSehrimNavHost(
    navController: NavHostController,
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val isLoggedIn by authViewModel.isLoggedIn.collectAsState()
    val startDestination = if (isLoggedIn) Screen.Home.route else Screen.Login.route

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Auth screens
        composable(Screen.Login.route) {
            LoginScreen(
                onNavigateToOtp = { phone ->
                    navController.navigate(Screen.Otp.createRoute(phone))
                }
            )
        }
        
        composable(
            route = Screen.Otp.route,
            arguments = listOf(navArgument("phone") { type = NavType.StringType })
        ) { backStackEntry ->
            val phone = backStackEntry.arguments?.getString("phone") ?: ""
            OtpScreen(
                phone = phone,
                onNavigateToRegister = { 
                    navController.navigate(Screen.Register.createRoute(phone))
                },
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(
            route = Screen.Register.route,
            arguments = listOf(navArgument("phone") { type = NavType.StringType })
        ) { backStackEntry ->
            val phone = backStackEntry.arguments?.getString("phone") ?: ""
            RegisterScreen(
                phone = phone,
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Main screens
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToStores = { categoryId ->
                    navController.navigate(Screen.Stores.createRoute(categoryId))
                },
                onNavigateToStore = { storeId ->
                    navController.navigate(Screen.StoreDetail.createRoute(storeId))
                },
                onNavigateToTaxi = {
                    navController.navigate(Screen.Taxi.route)
                },
                onNavigateToOrders = {
                    navController.navigate(Screen.Orders.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToCart = {
                    navController.navigate(Screen.Cart.route)
                }
            )
        }
        
        composable(
            route = Screen.Stores.route,
            arguments = listOf(navArgument("categoryId") { 
                type = NavType.StringType
                nullable = true
                defaultValue = null
            })
        ) { backStackEntry ->
            val categoryId = backStackEntry.arguments?.getString("categoryId")
            StoresScreen(
                categoryId = categoryId,
                onNavigateToStore = { storeId ->
                    navController.navigate(Screen.StoreDetail.createRoute(storeId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(
            route = Screen.StoreDetail.route,
            arguments = listOf(navArgument("storeId") { type = NavType.StringType })
        ) { backStackEntry ->
            val storeId = backStackEntry.arguments?.getString("storeId") ?: ""
            StoreDetailScreen(
                storeId = storeId,
                onNavigateToCart = { navController.navigate(Screen.Cart.route) },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.CreateStore.route) {
            CreateStoreScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Cart.route) {
            CartScreen(
                onNavigateToCheckout = {
                    navController.navigate(Screen.Checkout.route)
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Checkout.route) {
            CheckoutScreen(
                onNavigateBack = { navController.popBackStack() },
                onOrderSuccess = {
                    navController.navigate(Screen.OrderSuccess.route) {
                        popUpTo(Screen.Home.route) // Clear back stack
                    }
                }
            )
        }
        
        composable(Screen.OrderSuccess.route) {
            OrderSuccessScreen(
                onNavigateHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(0)
                    }
                },
                onNavigateOrders = {
                    navController.navigate(Screen.Orders.route) {
                        popUpTo(Screen.Home.route)
                    }
                }
            )
        }
        
        // Orders
        composable(Screen.Orders.route) {
            OrdersScreen(
                onNavigateToOrderDetail = { orderId ->
                    navController.navigate(Screen.OrderDetail.createRoute(orderId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(
            route = Screen.OrderDetail.route,
            arguments = listOf(navArgument("orderId") { type = NavType.StringType })
        ) { backStackEntry ->
            val orderId = backStackEntry.arguments?.getString("orderId") ?: ""
            OrderDetailScreen(
                orderId = orderId,
                onNavigateToChat = { chatId ->
                    navController.navigate(Screen.Chat.createRoute(chatId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Taxi
        composable(Screen.Taxi.route) {
            TaxiScreen(
                onNavigateToRide = { rideId ->
                    navController.navigate(Screen.RideDetail.createRoute(rideId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(
            route = Screen.RideDetail.route,
            arguments = listOf(navArgument("rideId") { type = NavType.StringType })
        ) { backStackEntry ->
            val rideId = backStackEntry.arguments?.getString("rideId") ?: ""
            RideDetailScreen(
                rideId = rideId,
                onNavigateToChat = { chatId ->
                    navController.navigate(Screen.Chat.createRoute(chatId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Courier (Customer)
        composable(Screen.CallCourier.route) {
            CallCourierScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Profile
        composable(Screen.Profile.route) {
            ProfileScreen(
                onNavigateToAddresses = {
                    navController.navigate(Screen.Addresses.route)
                },
                onNavigateToOrders = {
                    navController.navigate(Screen.Orders.route)
                },
                onNavigateToWallet = {
                    navController.navigate(Screen.Wallet.route)
                },
                onNavigateToFavorites = {
                    navController.navigate(Screen.Favorites.route)
                },
                onNavigateToVendor = {
                    navController.navigate(Screen.VendorDashboard.route)
                },
                onNavigateToCourier = {
                    navController.navigate(Screen.Courier.route)
                },

                onNavigateToDriver = {
                    navController.navigate(Screen.DriverDashboard.route)
                },
                onNavigateToAdmin = {
                    navController.navigate(Screen.Admin.route)
                },
                onLogout = {
                    authViewModel.logout()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Addresses.route) {
            AddressesScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Wallet.route) {
            WalletScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Favorites.route) {
            FavoritesScreen(
                onNavigateToStore = { storeId ->
                    navController.navigate(Screen.StoreDetail.createRoute(storeId))
                },
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Dashboards
        composable(Screen.Admin.route) {
            AdminDashboardScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.VendorDashboard.route) {
            VendorDashboardScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.DriverDashboard.route) {
            DriverDashboardScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Courier (Driver Mode)
         composable(Screen.Courier.route) {
            CourierScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
        
        // Chat
        composable(
            route = Screen.Chat.route,
            arguments = listOf(navArgument("chatId") { type = NavType.StringType })
        ) { backStackEntry ->
            val chatId = backStackEntry.arguments?.getString("chatId") ?: ""
            ChatScreen(
                chatId = chatId,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
