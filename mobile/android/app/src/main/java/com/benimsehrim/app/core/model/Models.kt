package com.benimsehrim.app.core.model

import com.google.gson.annotations.SerializedName

// ==================== AUTH MODELS ====================

data class SendOtpRequest(
    val phone: String
)

data class SendOtpResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("expires_in") val expiresIn: Int,
    val isNewUser: Boolean? = null
)

data class VerifyOtpRequest(
    val phone: String,
    val otp: String
)

data class RegisterRequest(
    val phone: String,
    val name: String,
    val email: String? = null,
    val cityId: String,
    val districtId: String? = null
)

data class RefreshTokenRequest(
    val refreshToken: String
)

data class AuthResponse(
    val accessToken: String? = null,
    val refreshToken: String? = null,
    val user: User? = null,
    val isNewUser: Boolean = false,
    val phone: String? = null,
    val message: String? = null
)

// ==================== USER MODELS ====================

data class User(
    val id: String,
    val phone: String,
    val name: String?,
    val email: String?,
    val avatarUrl: String?,
    val role: String,
    val city: City?,
    val district: District?,
    val balance: Double = 0.0, // Cüzdan Bakiyesi
    val createdAt: String?,
    val driver: Driver? = null,
    val courier: Courier? = null
)


data class UpdateUserRequest(
    val name: String? = null,
    val email: String? = null,
    val cityId: String? = null,
    val districtId: String? = null
)

data class Address(
    val id: String,
    val title: String,
    val address: String,
    val latitude: Double,
    val longitude: Double,
    val note: String?,
    val isDefault: Boolean
)

data class AddAddressRequest(
    val title: String,
    val address: String,
    val latitude: Double,
    val longitude: Double,
    val note: String? = null,
    val isDefault: Boolean = false
)

// ==================== LOCATION MODELS ====================

data class City(
    val id: String,
    val name: String,
    val code: String,
    val isActive: Boolean
)

data class District(
    val id: String,
    val name: String,
    val cityId: String,
    val isActive: Boolean
)

// ==================== STORE MODELS ====================

data class Store(
    val id: String,
    val name: String,
    val logoUrl: String?,
    val bannerUrl: String?,
    val rating: Double,
    val reviewCount: Int,
    val isOpen: Boolean,
    val distance: Double?,
    val deliveryTime: String?,
    val minOrder: Double,
    val deliveryFee: Double,
    val categories: List<Category>?,
    val isFavorite: Boolean = false,
    // Operations
    val isBusy: Boolean = false,
    val busyAutoMode: Boolean = true,
    val cancelCount: Int = 0,
    val usageScore: Double = 0.0
)

data class StoreDetail(
    val id: String,
    val name: String,
    val description: String?,
    val logoUrl: String?,
    val bannerUrl: String?,
    val address: String,
    val phone: String?,
    val rating: Double,
    val reviewCount: Int,
    val isOpen: Boolean,
    val openTime: String,
    val closeTime: String,
    val paymentTypes: List<String>,
    val minOrder: Double,
    val deliveryFee: Double,
    val products: List<Product>,
    val campaigns: List<Campaign>
)

data class Category(
    val id: String,
    val name: String,
    val icon: String?,
    val sortOrder: Int
)

// ==================== PRODUCT MODELS ====================

data class Product(
    val id: String,
    val name: String,
    val description: String?,
    val price: Double,
    val discountPrice: Double? = null,
    val stock: Int,
    val unit: String?,
    val images: List<String>,
    val isActive: Boolean,
    val campaigns: List<Campaign>?
)

data class Campaign(
    val id: String,
    val type: String,
    val value: Double,
    val startDate: String,
    val endDate: String,
    val stockLimit: Int?,
    val remainingStock: Int?,
    val product: Product?,
    val store: Store?
)

// ==================== ORDER MODELS ====================

data class CreateOrderRequest(
    val storeId: String,
    val items: List<OrderItemRequest>,
    val addressId: String,
    val addressNote: String? = null,
    val paymentType: String
)

data class OrderItemRequest(
    val productId: String,
    val quantity: Int,
    val campaignId: String? = null
)

data class Order(
    val id: String,
    val orderNo: String,
    val store: Store,
    val status: String,
    val total: Double,
    val itemCount: Int?,
    val createdAt: String
)

data class OrderDetail(
    val id: String,
    val orderNo: String,
    val store: Store,
    val status: String,
    val items: List<OrderItem>,
    val subtotal: Double,
    val discount: Double,
    val deliveryFee: Double,
    val total: Double,
    val address: Address,
    val paymentType: String,
    val courier: Courier?,
    val timeline: List<OrderTimeline>,
    val chatEnabled: Boolean,
    val createdAt: String
)

data class OrderItem(
    val id: String,
    val product: Product,
    val quantity: Int,
    val unitPrice: Double,
    val totalPrice: Double
)

data class OrderTimeline(
    val status: String,
    val time: String,
    val note: String?
)

data class Courier(
    val id: String,
    val name: String?,
    val phone: String?,

    val latitude: Double?,
    val longitude: Double?,
    // Operations
    val isBusy: Boolean = false,
    val dailyGoal: Int = 15,
    val usageScore: Double = 0.0
)

// ==================== TAXI MODELS ====================

data class EstimateFareRequest(
    val pickupLatitude: Double,
    val pickupLongitude: Double,
    val dropLatitude: Double,
    val dropLongitude: Double
)

data class FareEstimate(
    val distance: Double,
    val duration: Int,
    val estimatedFare: FareRange,
    val nearbyDrivers: Int
)

data class FareRange(
    val min: Double,
    val max: Double
)

data class NearbyDriver(
    val id: String,
    val latitude: Double,
    val longitude: Double,
    val distance: Double?
)

data class RequestRideRequest(
    val pickupLatitude: Double,
    val pickupLongitude: Double,
    val pickupAddress: String,
    val dropLatitude: Double,
    val dropLongitude: Double,
    val dropAddress: String
)

data class Ride(
    val id: String,
    val status: String,
    val pickupAddress: String,
    val dropAddress: String,
    val estimatedFare: FareRange?,
    val createdAt: String
)

data class RideDetail(
    val id: String,
    val status: String,
    val driver: Driver?,
    val pickupAddress: String,
    val dropAddress: String,
    val estimatedFare: FareRange?,
    val actualFare: Double?,
    val chatEnabled: Boolean,
    val createdAt: String,
    val startedAt: String?,
    val completedAt: String?
)

data class Driver(
    val id: String,
    val name: String?,
    val phone: String?,
    val photoUrl: String?,
    val rating: Double,
    val vehicle: Vehicle?,
    val latitude: Double?,
    val longitude: Double?,
    val eta: Int?,
    // Operations
    val isBusy: Boolean = false,
    val dailyGoal: Int = 10,
    val usageScore: Double = 0.0
)

data class Vehicle(
    val plate: String,
    val model: String?,
    val color: String?
)

// ==================== CHAT MODELS ====================

data class Chat(
    val id: String,
    val type: String,
    val isActive: Boolean,
    val partner: ChatPartner?
)

data class ChatPartner(
    val name: String,
    val role: String
)

data class ChatMessagesResponse(
    val data: List<Message>,
    val chat: Chat?
)

data class Message(
    val id: String,
    val senderId: String,
    val senderName: String?,
    val content: String,
    val isMine: Boolean?,
    val createdAt: String
)

data class SendMessageRequest(
    val content: String
)

// ==================== REVIEW MODELS ====================

data class ReviewsResponse(
    val data: List<Review>,
    val averageRating: Double,
    val totalReviews: Int
)

data class Review(
    val id: String,
    val user: ReviewUser?,
    val rating: Int,
    val comment: String?,
    val createdAt: String
)

data class ReviewUser(
    val name: String?
)

data class CreateReviewRequest(
    val targetType: String,
    val targetId: String,
    val orderId: String? = null,
    val rideId: String? = null,
    val rating: Int,
    val comment: String? = null
)

// ==================== SUPPORT MODELS ====================

data class CreateTicketRequest(
    val type: String,
    val orderId: String? = null,
    val rideId: String? = null,
    val subject: String,
    val description: String? = null
)

data class Ticket(
    val id: String,
    val ticketNo: String,
    val type: String,
    val subject: String,
    val status: String,
    val createdAt: String
)

data class TicketDetail(
    val id: String,
    val ticketNo: String,
    val type: String,
    val subject: String,
    val description: String?,
    val status: String,
    val replies: List<TicketReply>,
    val createdAt: String
)

data class TicketReply(
    val id: String,
    val content: String,
    val isAdmin: Boolean,
    val createdAt: String
)

data class ReplyTicketRequest(
    val content: String
)

// ==================== NOTIFICATION MODELS ====================

data class Notification(
    val id: String,
    val type: String,
    val title: String,
    val body: String,
    val data: Map<String, Any>?,
    val isRead: Boolean,
    val createdAt: String
)

data class UnreadCountResponse(
    val count: Int
)

data class PushTokenRequest(
    val token: String,
    val platform: String
)

// ==================== COMMON MODELS ====================

data class PaginatedResponse<T>(
    val data: List<T>,
    val meta: PaginationMeta
)

data class PaginationMeta(
    val total: Int,
    val page: Int,
    val limit: Int
)

data class ApiError(
    val statusCode: Int,
    val message: String,
    val error: String?
)

// ==================== ADMIN MODELS ====================

data class AdminDashboardResponse(
    val keyMetrics: AdminMetrics,
    val activeCrisis: Int
)

data class AdminMetrics(
    val activeUsers: Int,
    val dailyOrders: Int
    // Add other fields as needed matching backend
)

data class CrisisLog(
    val id: String,
    val title: String,
    val message: String?,
    val severity: String, // HIGH, MEDIUM, LOW
    val resolved: Boolean,
    val createdAt: String
)
