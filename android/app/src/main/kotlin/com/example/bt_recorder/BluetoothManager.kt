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
                val stream = inputStream ?: return@Thread
                val commandBuilder = StringBuilder()

                while (true) {
                    val byteRead = stream.read()
                    if (byteRead == -1) {
                        println("Socket connection closed")
                        onCommandReceived?.invoke("DISCONNECTED")
                        break
                    }

                    if (byteRead == '\n'.code) {
                        val command = commandBuilder.toString().trim()
                        commandBuilder.setLength(0)

                        if (command.startsWith("FILE_START|")) {
                            val parts = command.split("|")
                            if (parts.size >= 3) {
                                val filename = parts[1]
                                val fileSize = parts[2].toLongOrNull() ?: 0L
                                receiveFile(filename, fileSize)
                            }
                        } else if (command.isNotEmpty()) {
                            println("COMMAND RECEIVED: $command")
                            onCommandReceived?.invoke(command)
                        }
                    } else {
                        commandBuilder.append(byteRead.toChar())
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                onCommandReceived?.invoke("DISCONNECTED")
            }
        }.start()
    }

    private fun receiveFile(filename: String, fileSize: Long) {
        try {
            println("START RECEIVING FILE: $filename, size: $fileSize")
            onCommandReceived?.invoke("FILE_TRANSFER_START|$filename|$fileSize")

            val cacheDir = context.cacheDir
            val outputFile = java.io.File(cacheDir, filename)
            if (outputFile.exists()) {
                outputFile.delete()
            }

            val fileOut = java.io.FileOutputStream(outputFile)
            val buffer = ByteArray(8192)
            var bytesReadTotal = 0L
            val stream = inputStream ?: throw Exception("Input stream is null")

            var lastPercent = -1

            while (bytesReadTotal < fileSize) {
                val remaining = fileSize - bytesReadTotal
                val toRead = if (remaining > buffer.size) buffer.size else remaining.toInt()

                val read = stream.read(buffer, 0, toRead)
                if (read == -1) {
                    throw Exception("Stream closed/disconnected during file transfer")
                }

                fileOut.write(buffer, 0, read)
                bytesReadTotal += read

                val percent = ((bytesReadTotal * 100) / fileSize).toInt()
                if (percent != lastPercent) {
                    lastPercent = percent
                    onCommandReceived?.invoke("FILE_TRANSFER_PROGRESS|$percent")
                }
            }

            fileOut.flush()
            fileOut.close()

            println("FILE RECEIVED SUCCESSFULLY: ${outputFile.absolutePath}")
            onCommandReceived?.invoke("FILE_TRANSFER_COMPLETE|${outputFile.absolutePath}")

        } catch (e: Exception) {
            e.printStackTrace()
            onCommandReceived?.invoke("FILE_TRANSFER_FAILED|${e.message}")
        }
    }

    fun sendFile(filePath: String, progressCallback: ((Int) -> Unit)? = null): Boolean {
        return try {
            val file = java.io.File(filePath)
            if (!file.exists()) {
                println("File does not exist: $filePath")
                return false
            }

            val filename = file.name
            val fileSize = file.length()

            // 1. Send the header
            val header = "FILE_START|$filename|$fileSize\n"
            outputStream?.write(header.toByteArray())
            outputStream?.flush()

            // 2. Send the file bytes in chunks
            val fileIn = java.io.FileInputStream(file)
            val buffer = ByteArray(8192)
            var bytesSent = 0L

            while (true) {
                val read = fileIn.read(buffer)
                if (read == -1) break

                outputStream?.write(buffer, 0, read)
                bytesSent += read

                val percent = ((bytesSent * 100) / fileSize).toInt()
                progressCallback?.invoke(percent)
            }

            outputStream?.flush()
            fileIn.close()

            println("FILE SENT SUCCESSFULLY: $filePath")
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
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
        println("Ashwani:- START DISCOVERY CALLED")
        bluetoothAdapter?.cancelDiscovery()
        bluetoothAdapter?.startDiscovery()
        println("Ashwani:- DISCOVERY STARTED")
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
    onCommandReceived?.invoke("CONNECTED")
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
            startListening()
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