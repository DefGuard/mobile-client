package net.defguard.qr_plugin

import android.app.Activity
import android.graphics.Matrix
import android.hardware.display.DisplayManager
import android.util.Size
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.camera.core.SurfaceRequest
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.mlkit.vision.MlKitAnalyzer
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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.Future
import kotlin.math.min

private val RESOLUTION = ResolutionSelector.Builder()
    .setAspectRatioStrategy(AspectRatioStrategy.RATIO_16_9_FALLBACK_AUTO_STRATEGY)
    .setResolutionStrategy(
        ResolutionStrategy(Size(1920, 1080), ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER),
    )
    .build()

// Beyond this, digital zoom upscales a 1080p stream past what the sensor resolves.
private const val MAX_ZOOM_RATIO = 3f
private const val METERING_SIZE = 0.35f

class QrPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private val scanners = mutableMapOf<Int, QrScanner>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        channel = MethodChannel(binding.binaryMessenger, "net.defguard.qr_plugin").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        scanners.values.forEach { it.dispose() }
        scanners.clear()
        this.binding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val id = call.arguments as Int
        when (call.method) {
            "create" -> create(id, result)

            "dispose" -> {
                scanners.remove(id)?.dispose()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun create(id: Int, result: MethodChannel.Result) {
        val binding = binding ?: return result.error("cameraError", "Plugin detached from engine", null)
        val activity = activity
        if (activity !is LifecycleOwner) {
            return result.error("cameraError", "No lifecycle-aware host activity", null)
        }
        val scanner = QrScanner(activity, activity, binding.textureRegistry, binding.binaryMessenger, id)
        scanners.put(id, scanner)?.dispose()
        result.success(scanner.textureId)
    }

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

private class QrScanner(
    private val activity: Activity,
    private val host: LifecycleOwner,
    textureRegistry: TextureRegistry,
    messenger: BinaryMessenger,
    id: Int,
) : LifecycleOwner {
    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = registry

    private val hostObserver = LifecycleEventObserver { _, event -> registry.handleLifecycleEvent(event) }
    private val mainExecutor = ContextCompat.getMainExecutor(activity)
    private val channel = MethodChannel(messenger, "net.defguard.qr_plugin/scanner_$id")
    private val producer = textureRegistry.createSurfaceProducer()
    private val displayManager = activity.getSystemService(DisplayManager::class.java)
    private val preview = Preview.Builder().setResolutionSelector(RESOLUTION).build()
    private val analysis = ImageAnalysis.Builder().setResolutionSelector(RESOLUTION).build()
    private val surfaceProvider = Preview.SurfaceProvider(::provideSurface)
    private var provider: ProcessCameraProvider? = null
    private var scanner: BarcodeScanner? = null
    private var active = true
    private var disposed = false

    val textureId: Long get() = producer.id()

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}

        override fun onDisplayRemoved(displayId: Int) {}

        override fun onDisplayChanged(displayId: Int) = updateRotation()
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
        producer.setCallback(
            object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() = preview.setSurfaceProvider(surfaceProvider)

                override fun onSurfaceCleanup() = preview.setSurfaceProvider(null)
            },
        )
        preview.setSurfaceProvider(surfaceProvider)
        updateRotation()
        displayManager.registerDisplayListener(displayListener, null)
        host.lifecycle.addObserver(hostObserver)
        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({ bind(future) }, mainExecutor)
    }

    private fun provideSurface(request: SurfaceRequest) {
        val resolution = request.resolution
        producer.setSize(resolution.width, resolution.height)
        // The ImageReader-backed producer does not apply buffer rotation, so Dart rotates the texture.
        request.setTransformationInfoListener(mainExecutor) { info ->
            channel.invokeMethod(
                "size",
                mapOf(
                    "width" to resolution.width,
                    "height" to resolution.height,
                    "quarterTurns" to info.rotationDegrees / 90,
                ),
            )
        }
        request.provideSurface(producer.surface, mainExecutor) {}
    }

    private fun updateRotation() {
        val rotation = activity.display?.rotation ?: return
        preview.targetRotation = rotation
        analysis.targetRotation = rotation
    }

    private fun bind(future: Future<ProcessCameraProvider>) {
        if (disposed) return
        val camera = try {
            val provider = future.get().also { provider = it }
            if (!provider.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA)) {
                return fail("noCamera", "No back camera available")
            }
            provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis)
        } catch (e: Exception) {
            return fail("cameraError", (e.cause ?: e).toString())
        }
        camera.cameraInfo.cameraState.observe(this) { state ->
            val error = state.error
            when {
                error?.type == CameraState.ErrorType.CRITICAL -> fail("cameraError", "Camera state error ${error.code}")
                state.type == CameraState.Type.OPEN -> meterScanWindow(camera)
            }
        }
        camera.cameraInfo.zoomState.observe(this) { if (scanner == null) startScanner(camera, it.maxZoomRatio) }
    }

    // Whole-frame metering exposes for a dim room and blows out a QR code shown on a bright screen.
    private fun meterScanWindow(camera: Camera) {
        val point = SurfaceOrientedMeteringPointFactory(1f, 1f).createPoint(0.5f, 0.5f, METERING_SIZE)
        val action = FocusMeteringAction.Builder(point, FocusMeteringAction.FLAG_AE or FocusMeteringAction.FLAG_AWB)
            .disableAutoCancel()
            .build()
        camera.cameraControl.startFocusAndMetering(action)
    }

    private fun startScanner(camera: Camera, maxZoomRatio: Float) {
        val zoom = ZoomSuggestionOptions.Builder { ratio ->
            mainExecutor.execute { camera.cameraControl.setZoomRatio(ratio) }
            true
        }.setMaxSupportedZoomRatio(min(maxZoomRatio, MAX_ZOOM_RATIO)).build()
        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .setZoomSuggestionOptions(zoom)
            .build()
        val scanner = BarcodeScanning.getClient(options).also { scanner = it }
        val analyzer = MlKitAnalyzer(
            listOf(scanner),
            ImageAnalysis.COORDINATE_SYSTEM_ORIGINAL,
            mainExecutor,
        ) { result ->
            val value = result.getValue(scanner)?.firstNotNullOfOrNull { it.rawValue?.ifEmpty { null } }
            if (active && value != null) channel.invokeMethod("code", value)
        }
        analysis.setAnalyzer(mainExecutor, GatedAnalyzer(analyzer) { active })
    }

    private fun fail(code: String, message: String) =
        channel.invokeMethod("error", mapOf("code" to code, "message" to message))

    fun dispose() {
        if (disposed) return
        disposed = true
        active = false
        channel.setMethodCallHandler(null)
        displayManager.unregisterDisplayListener(displayListener)
        host.lifecycle.removeObserver(hostObserver)
        analysis.clearAnalyzer()
        preview.setSurfaceProvider(null)
        provider?.unbind(preview, analysis)
        if (registry.currentState.isAtLeast(Lifecycle.State.CREATED)) {
            registry.currentState = Lifecycle.State.DESTROYED
        }
        producer.release()
        scanner?.close()
    }
}

// Drops frames while paused so ML Kit does no work, without rebinding the camera.
private class GatedAnalyzer(private val inner: ImageAnalysis.Analyzer, private val enabled: () -> Boolean) :
    ImageAnalysis.Analyzer {
    override fun analyze(image: ImageProxy) = if (enabled()) inner.analyze(image) else image.close()

    override fun getDefaultTargetResolution(): Size? = inner.defaultTargetResolution

    override fun getTargetCoordinateSystem(): Int = inner.targetCoordinateSystem

    override fun updateTransform(matrix: Matrix?) = inner.updateTransform(matrix)
}
