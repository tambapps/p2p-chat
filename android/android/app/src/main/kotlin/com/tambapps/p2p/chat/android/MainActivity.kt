package com.tambapps.p2p.chat.android

import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

  // TODO use flutter plugin to acquire smart lock only when needed
  lateinit var lock: WifiManager.MulticastLock
  override fun onStart() {
    super.onStart()
    val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
    lock = wifiManager.createMulticastLock("MYLOCK")
    lock.acquire()
    lock.setReferenceCounted(true)
  }

  override fun onStop() {
    super.onStop()
    lock.release()
  }
}
