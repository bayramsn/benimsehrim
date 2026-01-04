package com.benimsehrim.vendor.feature.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    var showLogoutDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ayarlar") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Store Settings
            item {
                SettingsSection("Mağaza Ayarları")
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Store,
                    title = "Mağaza Bilgileri",
                    subtitle = "Ad, adres, telefon",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Schedule,
                    title = "Çalışma Saatleri",
                    subtitle = "08:00 - 22:00",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.LocalShipping,
                    title = "Teslimat Ayarları",
                    subtitle = "Min sipariş: 50₺, Teslimat: 10₺",
                    onClick = { }
                )
            }

            // Notifications
            item {
                SettingsSection("Bildirimler")
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Notifications,
                    title = "Bildirim Ayarları",
                    subtitle = "Sipariş, mesaj bildirimleri",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.VolumeUp,
                    title = "Sipariş Sesi",
                    subtitle = "Açık",
                    onClick = { }
                )
            }

            // Account
            item {
                SettingsSection("Hesap")
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Person,
                    title = "Profil",
                    subtitle = "+90 500 123 45 68",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Security,
                    title = "Güvenlik",
                    subtitle = "Şifre değiştir",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.AccountBalance,
                    title = "Banka Bilgileri",
                    subtitle = "Hesap bilgilerini düzenle",
                    onClick = { }
                )
            }

            // Support
            item {
                SettingsSection("Destek")
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Help,
                    title = "Yardım",
                    subtitle = "SSS ve iletişim",
                    onClick = { }
                )
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Description,
                    title = "Kullanım Koşulları",
                    onClick = { }
                )
            }

            // Logout
            item {
                Spacer(modifier = Modifier.height(24.dp))
            }
            item {
                SettingsItem(
                    icon = Icons.Default.Logout,
                    title = "Çıkış Yap",
                    iconTint = Color.Red,
                    titleColor = Color.Red,
                    onClick = { showLogoutDialog = true }
                )
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
                Text(
                    "Benim Şehrim Vendor v1.0.0",
                    modifier = Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
        }
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("Çıkış Yap") },
            text = { Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?") },
            confirmButton = {
                Button(
                    onClick = {
                        showLogoutDialog = false
                        onLogout()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                ) {
                    Text("Çıkış Yap")
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("İptal")
                }
            }
        )
    }
}

@Composable
fun SettingsSection(title: String) {
    Text(
        title,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.primary
    )
}

@Composable
fun SettingsItem(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    iconTint: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    titleColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, color = titleColor)
                if (subtitle != null) {
                    Text(
                        subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color.Gray
            )
        }
    }
    HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
}
