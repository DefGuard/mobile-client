package net.defguard.wireguard_plugin

import com.wireguard.android.backend.Tunnel

class SimpleTunnel(private val tunnelName: String) : Tunnel {
    override fun getName(): String = tunnelName

    override fun onStateChange(newState: Tunnel.State) {
        // TODO: bride to UI tunnel state changes
    }
}