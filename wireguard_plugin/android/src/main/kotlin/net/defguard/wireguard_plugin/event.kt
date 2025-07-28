package net.defguard.wireguard_plugin

import kotlinx.serialization.Serializable

enum class WireguardPluginEvent(val value: String) {
    TUNNEL_UP("tunnel_up"),
    TUNNEL_DOWN("tunnel_down"),
    TUNNEL_WAITING("tunnel_waiting"),
    MFA_SESSION_EXPIRED("mfa_session_expired"),
}

@Serializable
data class ActiveTunnelData(
    val instanceId: Int,
    val locationId: Int,
    val traffic: TunnelTraffic,
    val mfaEnabled: Boolean,
)
