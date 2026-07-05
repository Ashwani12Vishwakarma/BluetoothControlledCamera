package com.example.bt_recorder

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import java.io.InputStream
import java.io.OutputStream
import java.util.*

class BluetoothManager(private val context: Context) {

    var onCommandReceived: ((String) -> Unit)? = null

    private fun startListening() {
    Thread {
        try {
            val buffer = ByteArray(1024)

            while (true) {
                val bytes = inputStream?.read(buffer) ?: break

                if (bytes > 0) {
                    val command = String(buffer, 0, bytes)
                    println("COMMAND RECEIVED: $command")
                    onCommandReceived?.invoke(command)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }.start()
}

     val bluetoothAdapter: BluetoothAdapter? =
        BluetoothAdapter.getDefaultAdapter()

    private var serverSocket: BluetoothServerSocket? = null
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null

    private val APP_NAME = "BT_RECORDER"
    private val UUID_APP: UUID =
        UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    var onDeviceFound: ((Map<String,String>) -> Unit)? = null

    @SuppressLint("MissingPermission")
    fun startDiscovery() {
        bluetoothAdapter?.cancelDiscovery()
        bluetoothAdapter?.startDiscovery()
    }

    fun scanDevices(): List<Map<String, String>> {
        val devices = mutableListOf<Map<String, String>>()

        bluetoothAdapter?.startDiscovery()

        bluetoothAdapter?.bondedDevices?.forEach {
            devices.add(
                mapOf(
                    "name" to (it.name ?: "Unknown"),
                    "address" to it.address
                )
            )
        }

        return devices
    }

    @SuppressLint("MissingPermission")
fun startServer(): String {
    return try {
        serverSocket =
            bluetoothAdapter?.listenUsingRfcommWithServiceRecord(
                APP_NAME,
                UUID_APP
            )

        Thread {
    try {
        println("SERVER STARTED")
        socket = serverSocket?.accept()
        println("CLIENT CONNECTED")

        socket?.let {
    inputStream = it.inputStream
    outputStream = it.outputStream
    println("STREAM READY")
    startListening()
}

    } catch (e: Exception) {
        e.printStackTrace()
    }
}.start()

        "Waiting for connection"
    } catch (e: Exception) {
        e.message ?: "Server error"
    }
}

    @SuppressLint("MissingPermission")
fun connect(address: String): String {
    return try {

        socket?.close()
        socket = null

        val device = bluetoothAdapter?.getRemoteDevice(address)
            ?: return "Device not found"

        bluetoothAdapter?.cancelDiscovery()

        socket = device.createRfcommSocketToServiceRecord(UUID_APP)
        socket?.connect()

        if (socket?.isConnected == true) {
            inputStream = socket?.inputStream
            outputStream = socket?.outputStream
            "Connected"
        } else {
            "Connection failed"
        }

    } catch (e: Exception) {
        e.printStackTrace()
        "Error: ${e.message}"
    }
}

    @SuppressLint("MissingPermission")
    fun pairDevice(address: String): Boolean {
        val device = bluetoothAdapter?.getRemoteDevice(address)
        return device?.createBond() ?: false
    }

    fun sendCommand(command: String): Boolean {

        return try {

            outputStream?.write("$command\n".toByteArray())
            outputStream?.flush()

            true

        } catch (e: Exception) {

            e.printStackTrace()

            false
        }
    }

    fun readCommand(): String? {
        return try {
            val buffer = ByteArray(1024)
            val bytes = inputStream?.read(buffer) ?: 0
            String(buffer, 0, bytes)
        } catch (e: Exception) {
            null
        }
    }
}