package com.example.bt_recorder

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.bluetooth.BluetoothDevice

class MainActivity : FlutterActivity() {
     private val CHANNEL = "bluetooth_channel"
    private val EVENT_CHANNEL = "bluetooth_events"

    private var eventSink: EventChannel.EventSink? = null
    private lateinit var bluetoothManager: BluetoothManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bluetoothManager = BluetoothManager(this)

        registerReceiver(
            discoveryReceiver,
            IntentFilter(BluetoothDevice.ACTION_FOUND)
        )   

        bluetoothManager.onCommandReceived = { command ->
        println("FROM RECEIVER CALLBACK: $command")

            runOnUiThread {
                eventSink?.success(command)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
            ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "scanDevices" -> {
                    result.success(bluetoothManager.scanDevices())
                }

                "startServer" -> {
                    result.success(bluetoothManager.startServer())
                }

                "connect" -> {
                    val address = call.argument<String>("address")
                    result.success(
                        bluetoothManager.connect(address!!)
                    )
                }

                "startDiscovery" -> {
                    bluetoothManager.startDiscovery()
                    result.success(null)
                }

                "sendCommand" -> {

                    val command = call.argument<String>("command")

                    if (command != null) {
                        val sent = bluetoothManager.sendCommand(command)
                        result.success(sent)
                    } else {
                        result.success(false)
                    }
                }

                "pairDevice" -> {
                val address = call.argument<String>("address")
                    if (address != null) {
                        val resultValue = bluetoothManager.pairDevice(address)
                        result.success(resultValue)
                    } else {
                        result.error("NO_ADDRESS", "Address missing", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {

            when (intent?.action) {
                BluetoothDevice.ACTION_FOUND -> {

                    val device =
                        intent.getParcelableExtra<BluetoothDevice>(
                            BluetoothDevice.EXTRA_DEVICE
                        )

                    device?.let {
                        val deviceMap = mapOf(
                            "type" to "device",
                            "name" to (it.name ?: "Unknown"),
                            "address" to it.address,
                            "bonded" to (it.bondState == BluetoothDevice.BOND_BONDED)
                        )

                        runOnUiThread {
                            eventSink?.success(deviceMap)   
                        }
                    }
                }
            }
        }
    }
}