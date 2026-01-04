package com.benimsehrim.app.core.network

import com.benimsehrim.app.core.data.TokenManager
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class AuthInterceptor @Inject constructor(
    private val tokenManager: TokenManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        // Skip auth for login/register endpoints
        if (originalRequest.url.encodedPath.contains("/auth/")) {
            return chain.proceed(originalRequest)
        }

        val token = runBlocking { tokenManager.getAccessToken() }
        
        val request = if (token != null) {
            originalRequest.newBuilder()
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .build()
        } else {
            originalRequest
        }

        val response = chain.proceed(request)

        // Handle 401 - Token expired
        if (response.code == 401) {
            response.close()
            
            // Try to refresh token
            val newToken = runBlocking { tokenManager.refreshToken() }
            
            return if (newToken != null) {
                val newRequest = originalRequest.newBuilder()
                    .header("Authorization", "Bearer $newToken")
                    .header("Content-Type", "application/json")
                    .build()
                chain.proceed(newRequest)
            } else {
                // Logout user
                runBlocking { tokenManager.clearTokens() }
                response
            }
        }

        return response
    }
}
