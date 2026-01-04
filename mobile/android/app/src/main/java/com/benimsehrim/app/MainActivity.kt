package com.benimsehrim.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.scale
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import dagger.hilt.android.AndroidEntryPoint
import com.benimsehrim.app.ui.theme.*
import com.benimsehrim.app.navigation.BenimSehrimNavHost
import com.benimsehrim.app.navigation.Screen
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.airbnb.lottie.compose.*

data class BottomNavItem(
    val route: String,
    val title: String,
    val icon: ImageVector
)

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BenimSehrimTheme {
                val navController = rememberNavController()
                
                val bottomNavItems = listOf(
                    BottomNavItem(Screen.Home.route, "Anasayfa", Icons.Default.Home),
                    BottomNavItem(Screen.Orders.route, "Siparişlerim", Icons.Default.Receipt),
                    BottomNavItem(Screen.Cart.route, "Sepetim", Icons.Default.ShoppingCart),
                    BottomNavItem(Screen.Profile.route, "Profilim", Icons.Default.Person)
                )

                Scaffold(
                    containerColor = BackgroundDark,
                    bottomBar = {
                        val navBackStackEntry by navController.currentBackStackEntryAsState()
                        val currentDestination = navBackStackEntry?.destination
                        val currentRoute = currentDestination?.route

                        // Show on main screens
                        if (currentRoute == Screen.Home.route || 
                            currentRoute == Screen.Orders.route || 
                            currentRoute == Screen.Cart.route || 
                            currentRoute == Screen.Profile.route) 
                        {
                                NavigationBar(
                                    containerColor = SurfaceDark,
                                    contentColor = TextSecondary,
                                    tonalElevation = 8.dp
                                ) {
                                    bottomNavItems.forEach { item ->
                                        val selected = currentDestination?.hierarchy?.any { 
                                            it.route == item.route 
                                        } == true
                                        
                                        val scale by animateFloatAsState(
                                            targetValue = if (selected) 1.2f else 1f,
                                            animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
                                            label = "scale"
                                        )

                                        NavigationBarItem(
                                            icon = { 
                                                Box(modifier = Modifier.scale(scale)) {
                                                    when (item.route) {
                                                        Screen.Cart.route -> {
                                                            val composition by rememberLottieComposition(LottieCompositionSpec.RawRes(R.raw.shopping_done))
                                                            LottieAnimation(
                                                                composition = composition,
                                                                iterations = if (selected) LottieConstants.IterateForever else 1,
                                                                modifier = Modifier.size(26.dp),
                                                                isPlaying = selected
                                                            )
                                                        }
                                                        Screen.Orders.route -> {
                                                            val composition by rememberLottieComposition(LottieCompositionSpec.RawRes(R.raw.payment_success))
                                                            LottieAnimation(
                                                                composition = composition,
                                                                iterations = if (selected) LottieConstants.IterateForever else 1,
                                                                modifier = Modifier.size(26.dp),
                                                                isPlaying = selected
                                                            )
                                                        }
                                                        else -> {
                                                            Icon(
                                                                item.icon, 
                                                                contentDescription = item.title,
                                                                tint = if (selected) Primary else TextSecondary,
                                                                modifier = Modifier.size(24.dp)
                                                            )
                                                        }
                                                    }
                                                }
                                            },
                                            label = { 
                                                Text(
                                                    item.title,
                                                    style = MaterialTheme.typography.labelSmall,
                                                    color = if (selected) Primary else TextSecondary,
                                                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
                                                ) 
                                            },
                                            selected = selected,
                                            alwaysShowLabel = true,
                                            colors = NavigationBarItemDefaults.colors(
                                                indicatorColor = Color.Transparent, // Transparent indicator for cleaner look with animations
                                                selectedIconColor = Primary,
                                                unselectedIconColor = TextSecondary,
                                                selectedTextColor = Primary,
                                                unselectedTextColor = TextSecondary
                                            ),
                                            onClick = {
                                                navController.navigate(item.route) {
                                                    popUpTo(navController.graph.findStartDestination().id) {
                                                        saveState = true
                                                    }
                                                    launchSingleTop = true
                                                    restoreState = true
                                                }
                                            }
                                        )
                                    }
                                }
                        }
                    }
                ) { innerPadding ->
                    // Use Centralized Navigation Host
                    // Pass modifier to respect Scaffold padding
                    androidx.compose.foundation.layout.Box(modifier = Modifier.padding(innerPadding)) {
                         BenimSehrimNavHost(
                            navController = navController
                        )
                    }
                }
            }
        }
    }
}
