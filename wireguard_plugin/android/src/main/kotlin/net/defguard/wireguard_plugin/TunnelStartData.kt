package net.defguard.wireguard_plugin

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class TunnelTraffic {
    @SerialName("all")
    ALL,

    @SerialName("predefined")
    PREDEFINED,
}

@Serializable
data class TunnelStartData(
    // config
    val publicKey: String,
    val privateKey: String,
    val address: String,
    val dns: String? = null,
    val endpoint: String,
    val allowedIps: String,
    val keepalive: Int,
    val presharedKey: String?,
    val traffic: TunnelTraffic,
    // context
    val locationName: String,
    val locationId: Int,
    val instanceId: Int,
    // Opaque MFA method identifier, passed through from Dart for display only.
    // Null when the tunnel was authorized without MFA.
    val mfaMethod: Int? = null
)