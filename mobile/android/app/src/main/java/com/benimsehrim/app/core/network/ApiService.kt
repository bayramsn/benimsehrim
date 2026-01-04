package com.benimsehrim.app.core.network

import com.benimsehrim.app.core.model.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // ==================== AUTH ====================
    
    @POST("auth/send-otp")
    suspend fun sendOtp(@Body request: SendOtpRequest): Response<SendOtpResponse>

    @POST("auth/verify-otp")
    suspend fun verifyOtp(@Body request: VerifyOtpRequest): Response<AuthResponse>

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<AuthResponse>

    // ==================== USER ====================
    
    @GET("users/me")
    suspend fun getMe(): Response<User>

    @PUT("users/me")
    suspend fun updateMe(@Body request: UpdateUserRequest): Response<User>

    @GET("users/addresses")
    suspend fun getAddresses(): Response<List<Address>>

    @POST("users/addresses")
    suspend fun addAddress(@Body request: AddAddressRequest): Response<Address>

    @PUT("users/addresses/{id}")
    suspend fun updateAddress(@Path("id") id: String, @Body request: AddAddressRequest): Response<Address>

    @DELETE("users/addresses/{id}")
    suspend fun deleteAddress(@Path("id") id: String): Response<Unit>

    // ==================== STORES ====================
    
    @GET("stores")
    suspend fun getStores(
        @Query("cityId") cityId: String? = null,
        @Query("categoryId") categoryId: String? = null,
        @Query("isOpen") isOpen: Boolean? = null,
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<PaginatedResponse<Store>>

    @GET("stores/{id}")
    suspend fun getStore(@Path("id") id: String): Response<StoreDetail>

    // ==================== PRODUCTS ====================
    
    @GET("products/store/{storeId}")
    suspend fun getProducts(@Path("storeId") storeId: String): Response<List<Product>>

    @GET("products/{id}")
    suspend fun getProduct(@Path("id") id: String): Response<Product>

    // ==================== CAMPAIGNS ====================
    
    @GET("campaigns")
    suspend fun getCampaigns(
        @Query("storeId") storeId: String? = null
    ): Response<List<Campaign>>

    // ==================== ORDERS ====================
    
    @POST("orders")
    suspend fun createOrder(@Body request: CreateOrderRequest): Response<Order>

    @GET("orders")
    suspend fun getOrders(
        @Query("status") status: String? = null
    ): Response<List<Order>>

    @GET("orders/{id}")
    suspend fun getOrder(@Path("id") id: String): Response<OrderDetail>

    // ==================== TAXI ====================
    
    @POST("taxi/estimate")
    suspend fun estimateFare(@Body request: EstimateFareRequest): Response<FareEstimate>

    @GET("taxi/nearby")
    suspend fun getNearbyDrivers(
        @Query("lat") lat: Double,
        @Query("lng") lng: Double,
        @Query("radius") radius: Double = 3.0
    ): Response<List<NearbyDriver>>

    @POST("taxi/request")
    suspend fun requestRide(@Body request: RequestRideRequest): Response<Ride>

    @GET("taxi/rides")
    suspend fun getRides(): Response<List<Ride>>

    @GET("taxi/rides/{id}")
    suspend fun getRide(@Path("id") id: String): Response<RideDetail>

    // ==================== CHAT ====================
    
    @GET("chats/{id}/messages")
    suspend fun getMessages(
        @Path("id") chatId: String,
        @Query("limit") limit: Int = 50
    ): Response<ChatMessagesResponse>

    @POST("chats/{id}/messages")
    suspend fun sendMessage(
        @Path("id") chatId: String,
        @Body request: SendMessageRequest
    ): Response<Message>

    @GET("chats/order/{orderId}")
    suspend fun getChatByOrder(@Path("orderId") orderId: String): Response<Chat?>

    @GET("chats/ride/{rideId}")
    suspend fun getChatByRide(@Path("rideId") rideId: String): Response<Chat?>

    // ==================== REVIEWS ====================
    
    @GET("reviews")
    suspend fun getReviews(
        @Query("targetType") targetType: String,
        @Query("targetId") targetId: String
    ): Response<ReviewsResponse>

    @POST("reviews")
    suspend fun createReview(@Body request: CreateReviewRequest): Response<Review>

    // ==================== SUPPORT ====================
    
    @POST("support/tickets")
    suspend fun createTicket(@Body request: CreateTicketRequest): Response<Ticket>

    @GET("support/tickets")
    suspend fun getTickets(): Response<List<Ticket>>

    @GET("support/tickets/{id}")
    suspend fun getTicket(@Path("id") id: String): Response<TicketDetail>

    @POST("support/tickets/{id}/reply")
    suspend fun replyToTicket(
        @Path("id") id: String,
        @Body request: ReplyTicketRequest
    ): Response<TicketReply>

    // ==================== NOTIFICATIONS ====================
    
    @GET("notifications")
    suspend fun getNotifications(): Response<PaginatedResponse<Notification>>

    @GET("notifications/unread-count")
    suspend fun getUnreadCount(): Response<UnreadCountResponse>

    @PUT("notifications/{id}/read")
    suspend fun markAsRead(@Path("id") id: String): Response<Unit>

    @PUT("notifications/read-all")
    suspend fun markAllAsRead(): Response<Unit>

    @PUT("notifications/push-token")
    suspend fun registerPushToken(@Body request: PushTokenRequest): Response<Unit>

    // ==================== FEATURES ====================
    
    @GET("features/me")
    suspend fun getMyFeatures(): Response<Map<String, Boolean>>

    // ==================== VENDOR PANEL ====================
    
    @GET("stores/me")
    suspend fun getMyStore(): Response<Store>

    @GET("stores/me/dashboard")
    suspend fun getVendorDashboard(): Response<Store> // Returns augmented store object

    @PUT("stores/{id}/status")
    suspend fun updateStoreStatus(
        @Path("id") id: String,
        @Body request: Map<String, Boolean> // isOpen
    ): Response<Unit>

    @PUT("stores/{id}/busy")
    suspend fun updateStoreBusy(
        @Path("id") id: String,
        @Body request: Map<String, Boolean> // isBusy
    ): Response<Unit>


    // ==================== DRIVER PANEL ====================

    @PUT("taxi/driver/status")
    suspend fun updateDriverStatus(@Body request: Map<String, Any>): Response<Unit> // isOnline

    @PUT("taxi/driver/busy")
    suspend fun updateDriverBusy(@Body request: Map<String, Boolean>): Response<Unit> // isBusy

    @PUT("taxi/driver/rest")
    suspend fun toggleRestMode(@Body request: Map<String, Int>): Response<Unit> // duration

    // ==================== ADMIN PANEL ====================

    @GET("admin/dashboard")
    suspend fun getAdminDashboard(): Response<AdminDashboardResponse>

    @GET("admin/crisis/logs")
    suspend fun getCrisisLogs(): Response<List<CrisisLog>>

    @PUT("admin/crisis/{id}/resolve")
    suspend fun resolveCrisisLog(@Path("id") id: String): Response<Unit>
}
