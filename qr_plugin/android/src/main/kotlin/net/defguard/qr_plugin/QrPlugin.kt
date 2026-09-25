package net.defguard.qr_plugin

import android.app.Activity
import android.content.Context
import android.util.Size
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.mlkit.vision.MlKitAnalyzer
import androidx.camera.view.CameraController
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.ZoomSuggestionOptions
import com.google.mlkit.vision.barcode.common.Barcode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class QrPlugin : FlutterPlugin, ActivityAware {
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "net.defguard.qr_plugin/view",
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
                    QrView(context, activity as LifecycleOwner, binding.binaryMessenger, args as Int)
            },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}

private class QrView(
    context: Context,
    private val host: LifecycleOwner,
    messenger: BinaryMessenger,
    channelId: Int,
) : PlatformView, LifecycleOwner {
    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = registry

    private val hostObserver = LifecycleEventObserver { _, event -> registry.handleLifecycleEvent(event) }
    private val mainExecutor = ContextCompat.getMainExecutor(context)
    private val channel = MethodChannel(messenger, "net.defguard.qr_plugin/view_$channelId")
    private var scanner: BarcodeScanner? = null
    private var active = true

    private val controller = LifecycleCameraController(context).apply {
        cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        setEnabledUseCases(CameraController.IMAGE_ANALYSIS)
        imageAnalysisResolutionSelector = ResolutionSelector.Builder()
            .setAspectRatioStrategy(AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY)
            .setResolutionStrategy(
                ResolutionStrategy(Size(1280, 960), ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER),
            )
            .build()
    }

    private val previewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
        controller = this@QrView.controller
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> active = true
                "stop" -> active = false
                else -> return@setMethodCallHandler result.notImplemented()
            }
            result.success(null)
        }
        host.lifecycle.addObserver(hostObserver)
        controller.bindToLifecycle(this)
        controller.initializationFuture.addListener({
            val error = runCatching { controller.initializationFuture.get() }.exceptionOrNull()
            when {
                error != null -> fail("cameraError", (error.cause ?: error).toString())
                !controller.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA) -> fail("noCamera", "No back camera available")
            }
        }, mainExecutor)
        controller.zoomState.observe(this) { if (scanner == null) startScanner(it.maxZoomRatio) }
    }

    private fun startScanner(maxZoomRatio: Float) {
        val zoom = ZoomSuggestionOptions.Builder { ratio ->
            mainExecutor.execute { controller.setZoomRatio(ratio) }
            true
        }.setMaxSupportedZoomRatio(maxZoomRatio).build()
        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .setZoomSuggestionOptions(zoom)
            .build()
        val scanner = BarcodeScanning.getClient(options).also { scanner = it }
        controller.setImageAnalysisAnalyzer(
            mainExecutor,
            MlKitAnalyzer(listOf(scanner), ImageAnalysis.COORDINATE_SYSTEM_ORIGINAL, mainExecutor) { result ->
                val value = result.getValue(scanner)?.firstNotNullOfOrNull { it.rawValue?.ifEmpty { null } }
                if (active && value != null) channel.invokeMethod("code", value)
            },
        )
    }

    private fun fail(code: String, message: String) =
        channel.invokeMethod("error", mapOf("code" to code, "message" to message))

    override fun getView(): View = previewView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        host.lifecycle.removeObserver(hostObserver)
        controller.clearImageAnalysisAnalyzer()
        if (registry.currentState.isAtLeast(Lifecycle.State.CREATED)) {
            registry.currentState = Lifecycle.State.DESTROYED
        }
        scanner?.close()
    }
}
