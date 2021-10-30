package com.tambapps.p2p.chat.android

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.launch

import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface
import java.util.*

class MainActivity: FlutterActivity() {

  // TODO use flutter plugin to acquire smart lock only when needed
  lateinit var lock: WifiManager.MulticastLock
  override fun onStart() {
    super.onStart()
    val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
    lock = wifiManager.createMulticastLock("MYLOCK")
    lock.setReferenceCounted(true)
    lock.acquire()
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tambapps/network").setMethodCallHandler {
        call, result ->
      when (call.method) {
        "listNetworkInterfacesForMulticast" -> CoroutineScope(Dispatchers.IO).launch {
          val listResult = kotlin.runCatching {
            findNetworkInterfacesForMulticast()
          }

          withContext(Dispatchers.Main) {
            if (listResult.isFailure) {
              val t = listResult.exceptionOrNull()!!
              result.error(t.javaClass.simpleName, t.message, null)
            } else {
              result.success(listResult.getOrNull()!!.map {
                // Flutter only handle 'simple' types
                mapOf<String, Any>(Pair("name", it.name), Pair("index", it.index))
              })
            }
          }
        }
        "acquireMulticastLock" -> {
          lock.acquire()
          result.success(null)
        }
        "releaseMulticastLock" -> {
          lock.release()
          result.success(null)
        }
        else -> {
          result.error("NoSuchMethod", "", null)
        }
      }
    }
  }
  override fun onStop() {
    super.onStop()
    lock.release()
  }

  private fun findNetworkInterfacesForMulticast(): List<NetworkInterface> {
    val enumeration: Enumeration<NetworkInterface> = NetworkInterface.getNetworkInterfaces()
    val interfaces = mutableListOf<NetworkInterface>()
    var i: NetworkInterface? = null
    while (enumeration.hasMoreElements()) {
      i = enumeration.nextElement()

      if (i != null && !i.isLoopback && i.supportsMulticast()) {
        interfaces.add(i)
      }
    }
    return interfaces
  }
}
