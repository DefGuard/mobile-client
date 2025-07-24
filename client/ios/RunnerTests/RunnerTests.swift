import Flutter
import UIKit
import XCTest
import wireguard_plugin

class RunnerTests: XCTestCase {
    var plugin: WireguardPlugin?
    var vpnManager: MockVPNManager = MockVPNManager()
    var capturedFlutterEvents: [Any?] = []
    var testSink: FlutterEventSink?

    override func setUp() {
        plugin = WireguardPlugin(vpnManager: vpnManager)
        let testSink: FlutterEventSink = { event in
            self.capturedFlutterEvents.append(event)
        }
        _ = plugin?.onListen(withArguments: nil, eventSink: testSink)
    }

    func flutterEventsMatch(_ expectedEvents: [WireguardEvent], orderMatters: Bool = true) {
        let expected = expectedEvents.map { $0.rawValue }
        let actual = capturedFlutterEvents.compactMap { $0 as? [String: Any] }
            .compactMap { $0["event"] as? String }

        XCTAssertEqual(actual.count, expected.count, "Flutter event counts do not match.")

        if orderMatters {
            XCTAssertEqual(actual, expected, "Flutter events do not match expected sequence.")
        } else {
            XCTAssertTrue(
                Set(actual).isSuperset(of: Set(expected)),
                "Flutter events do not match expected set."
            )
        }
    }

    override func tearDown() {
        plugin = nil
        capturedFlutterEvents.removeAll()
    }

    let mockTunnelData = TunnelStartData(
        publicKey: "mockPublicKey",
        privateKey: "mockPrivateKey",
        address: "10.1.1.1/24",
        dns: "1.1.1.1",
        endpoint: "192.168.0.1",
        allowedIps: "10.1.1.1/24",
        keepalive: 25,
        presharedKey: "mockPresharedKey",
        traffic: .All,
        locationName: "Test Location",
        locationId: 1,
        instanceId: 1
    )

    func testConnectDisconnect() {
        XCTAssertNotNil(plugin, "Plugin should not be nil")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let dataString = try? String(
            data: encoder.encode(mockTunnelData),
            encoding: .utf8
        )
        XCTAssertNotNil(dataString, "Encoded data should not be nil")

        let call = FlutterMethodCall(
            methodName: "startTunnel",
            arguments: dataString
        )

        let connectExpecation = self.expectation(
            description: "startTunnel completion"
        )

        // Try connecting
        plugin?.handle(
            call,
            result: { result in
                let status = self.vpnManager.connectionStatus
                if status == .connected {
                    XCTAssertTrue(true, "Tunnel started successfully")
                } else {
                    XCTFail("Tunnel did not start successfully")
                }
                XCTAssertTrue(self.vpnManager.vpnEventsEqual([.connected]))
                self.flutterEventsMatch([.tunnelUp])
                connectExpecation.fulfill()
            }
        )

        // Try disconnecting
        let disconnectCall = FlutterMethodCall(methodName: "closeTunnel", arguments: nil)
        let disconnectExpectation = self.expectation(description: "closeTunnel completion")

        plugin?.handle(
            disconnectCall,
            result: { result in
                let status = self.vpnManager.connectionStatus
                if status == .disconnected {
                    XCTAssertTrue(true, "Tunnel stopped successfully")
                } else {
                    XCTFail("Tunnel did not stop successfully")
                }
                XCTAssertTrue(
                    self.vpnManager.vpnEventsEqual([.connected, .disconnected])
                )
                self.flutterEventsMatch([.tunnelUp, .tunnelDown])
                disconnectExpectation.fulfill()
            }
        )

        wait(for: [connectExpecation, disconnectExpectation], timeout: 5.0)
    }

    func testSystemConnectDisconnect() {
        XCTAssertNotNil(plugin, "Plugin should not be nil")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let dataString = try? String(
            data: encoder.encode(mockTunnelData),
            encoding: .utf8
        )
        XCTAssertNotNil(dataString, "Encoded data should not be nil")

        let call = FlutterMethodCall(methodName: "startTunnel", arguments: dataString)

        let connectExpecation = self.expectation(description: "startTunnel completion")

        // Try connecting
        plugin?.handle(
            call,
            result: { result in
                let status = self.vpnManager.connectionStatus
                if status == .connected {
                    XCTAssertTrue(true, "Tunnel started successfully")
                } else {
                    XCTFail("Tunnel did not start successfully")
                }
                XCTAssertTrue(self.vpnManager.vpnEventsEqual([.connected]))
                self.flutterEventsMatch([.tunnelUp])
                connectExpecation.fulfill()
            }
        )

        wait(for: [connectExpecation], timeout: 5.0)

        // Simulate system disconnect
        vpnManager.connectionStatus = .disconnected

        NotificationCenter.default.post(
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: vpnManager.providerManager?.connection
        )

        let disconnectExpectation = self.expectation(description: "System disconnect completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let status = self.vpnManager.connectionStatus
            if status == .disconnected {
                XCTAssertTrue(true, "Tunnel stopped successfully")
            } else {
                XCTFail("Tunnel did not stop successfully")
            }

            self.flutterEventsMatch([.tunnelUp, .tunnelDown])

            disconnectExpectation.fulfill()
        }

        wait(for: [disconnectExpectation], timeout: 5.0)

        // Simulate system reconnect
        vpnManager.connectionStatus = .connected
        NotificationCenter.default.post(
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: vpnManager.providerManager?.connection
        )

        let reconnectExpectation = self.expectation(
            description: "System reconnect completion"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let status = self.vpnManager.connectionStatus
            if status == .connected {
                XCTAssertTrue(true, "Tunnel reconnected successfully")
            } else {
                XCTFail("Tunnel did not reconnect successfully")
            }

            self.flutterEventsMatch([.tunnelUp, .tunnelDown, .tunnelUp])

            reconnectExpectation.fulfill()
        }

        wait(for: [reconnectExpectation], timeout: 5.0)
    }
}
