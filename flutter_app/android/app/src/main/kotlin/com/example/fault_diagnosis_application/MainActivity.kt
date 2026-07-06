package com.example.fault_diagnosis_application

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.OpenableColumns
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt
import org.pytorch.IValue
import org.pytorch.LiteModuleLoader
import org.pytorch.Tensor
import org.opencv.android.Utils
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.videoio.VideoCapture
import org.opencv.videoio.Videoio

/**
 * Android 네이티브 호스트 진입점.
 *
 * Flutter 화면에서 필요한 영상 처리/모델 추론은 MethodChannel 로 Android 네이티브 구현에 위임한다.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val HSV_PREVIEW_CHANNEL = "fault_diagnosis/hsv_preview"
        private const val DISPLACEMENT_CHANNEL = "fault_diagnosis/displacement"
        private const val DISPLACEMENT_PROGRESS_CHANNEL = "fault_diagnosis/displacement_progress"
        private const val DIAGNOSIS_CHANNEL = "fault_diagnosis/model"
        private const val FILE_METADATA_CHANNEL = "fault_diagnosis/file_metadata"
        private const val MODEL_INPUT_LENGTH = 2048
        private const val MODEL_ASSET_NAME = "Fwdcnn7.ptl"
        private const val PICK_LOCAL_VIDEO_REQUEST = 4217

        init {
            System.loadLibrary("opencv_java4")
        }
    }

    private var pendingLocalVideoResult: MethodChannel.Result? = null
    private var displacementProgressSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HSV_PREVIEW_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadRoiFrame" -> runNative(result) { loadRoiFrame(call) }
                "applyHsvFilter" -> runNative(result) { applyHsvFilter(call) }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DISPLACEMENT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "computeDisplacement" -> runNative(result) { computeDisplacement(call) }
                "shareCsv" -> shareCsv(call, result)
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DISPLACEMENT_PROGRESS_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                displacementProgressSink = events
            }

            override fun onCancel(arguments: Any?) {
                displacementProgressSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DIAGNOSIS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "diagnose" -> runNative(result) { diagnose(call) }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_METADATA_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickLocalVideo" -> pickLocalVideo(result)
                "resolveDisplayName" -> Thread {
                    try {
                        val displayName = resolveDisplayName(call)
                        runOnUiThread { result.success(displayName) }
                    } catch (error: Throwable) {
                        runOnUiThread {
                            result.error(
                                "FILE_METADATA_FAILED",
                                error.message ?: "File metadata lookup failed",
                                null
                            )
                        }
                    }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android API, but still supported by FlutterActivity.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_LOCAL_VIDEO_REQUEST) {
            val pending = pendingLocalVideoResult
            pendingLocalVideoResult = null

            if (pending == null) {
                super.onActivityResult(requestCode, resultCode, data)
                return
            }
            if (resultCode != RESULT_OK || data?.data == null) {
                pending.success(null)
                return
            }

            Thread {
                try {
                    val uri = data.data ?: throw IllegalStateException("선택된 영상 URI가 없습니다.")
                    val copied = copyPickedVideoToCache(uri)
                    runOnUiThread { pending.success(copied) }
                } catch (error: Throwable) {
                    runOnUiThread {
                        pending.error(
                            "LOCAL_VIDEO_PICK_FAILED",
                            error.message ?: "Local video pick failed",
                            null
                        )
                    }
                }
            }.start()
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun pickLocalVideo(result: MethodChannel.Result) {
        if (pendingLocalVideoResult != null) {
            result.error("PICKER_BUSY", "이미 영상 선택기가 열려 있습니다.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "video/*"
            putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        pendingLocalVideoResult = result
        try {
            startActivityForResult(intent, PICK_LOCAL_VIDEO_REQUEST)
        } catch (error: Throwable) {
            pendingLocalVideoResult = null
            result.error(
                "LOCAL_VIDEO_PICK_FAILED",
                error.message ?: "로컬 영상 선택기를 열지 못했습니다.",
                null
            )
        }
    }

    private fun shareCsv(call: MethodCall, result: MethodChannel.Result) {
        val csvUri = call.requiredArgument<String>("csvUri")
        val displayName = call.argument<String>("displayName") ?: "displacement.csv"
        try {
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/csv"
                putExtra(Intent.EXTRA_STREAM, Uri.parse(csvUri))
                putExtra(Intent.EXTRA_TITLE, displayName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(shareIntent, "CSV 내보내기"))
            result.success(true)
        } catch (error: Throwable) {
            result.error(
                "CSV_SHARE_FAILED",
                error.message ?: "CSV 공유 화면을 열지 못했습니다.",
                null
            )
        }
    }

    private fun sendDisplacementProgress(
        processed: Int,
        total: Int,
        detected: Int,
        missed: Int,
    ) {
        val progress = if (total <= 0) 0.0 else processed.toDouble() / total.toDouble()
        val payload = mapOf(
            "processed" to processed,
            "total" to total,
            "progress" to progress.coerceIn(0.0, 1.0),
            "detected" to detected,
            "missed" to missed
        )
        runOnUiThread {
            displacementProgressSink?.success(payload)
        }
    }

    private fun runNative(
        result: MethodChannel.Result,
        work: () -> Map<String, Any>
    ) {
        Thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (error: Throwable) {
                runOnUiThread {
                    result.error(
                        "NATIVE_PROCESSING_FAILED",
                        error.message ?: "Native processing failed",
                        null
                    )
                }
            }
        }.start()
    }

    private fun loadRoiFrame(call: MethodCall): Map<String, Any> {
        val videoPath = call.requiredArgument<String>("videoPath")
        val roiX = call.requiredDouble("x")
        val roiY = call.requiredDouble("y")
        val roiWidth = call.requiredDouble("width")
        val roiHeight = call.requiredDouble("height")

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(videoPath)
            val frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST)
                ?: throw IllegalStateException("첫 프레임을 읽지 못했습니다.")

            val left = (roiX * frame.width).toInt().coerceIn(0, frame.width - 1)
            val top = (roiY * frame.height).toInt().coerceIn(0, frame.height - 1)
            val right = ((roiX + roiWidth) * frame.width).toInt().coerceIn(left + 1, frame.width)
            val bottom = ((roiY + roiHeight) * frame.height).toInt().coerceIn(top + 1, frame.height)

            val cropped = Bitmap.createBitmap(frame, left, top, right - left, bottom - top)
            val bytes = cropped.toPngBytes()

            return mapOf(
                "bytes" to bytes,
                "width" to cropped.width,
                "height" to cropped.height
            )
        } finally {
            retriever.release()
        }
    }

    private fun applyHsvFilter(call: MethodCall): Map<String, Any> {
        val bytes = call.requiredArgument<ByteArray>("bytes")
        val hMin = call.requiredDouble("hMin")
        val hMax = call.requiredDouble("hMax")
        val sMin = call.requiredDouble("sMin")
        val sMax = call.requiredDouble("sMax")
        val vMin = call.requiredDouble("vMin")
        val vMax = call.requiredDouble("vMax")

        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IllegalStateException("ROI 이미지를 해석하지 못했습니다.")

        val rgbaMat = Mat()
        val rgbMat = Mat()
        val hsvMat = Mat()
        val maskMat = Mat()
        val filteredMat = Mat.zeros(bitmap.height, bitmap.width, org.opencv.core.CvType.CV_8UC4)

        try {
            Utils.bitmapToMat(bitmap, rgbaMat)
            Imgproc.cvtColor(rgbaMat, rgbMat, Imgproc.COLOR_RGBA2RGB)
            Imgproc.cvtColor(rgbMat, hsvMat, Imgproc.COLOR_RGB2HSV)

            Core.inRange(
                hsvMat,
                Scalar(hMin, sMin, vMin),
                Scalar(hMax, sMax, vMax),
                maskMat
            )
            rgbaMat.copyTo(filteredMat, maskMat)

            val resultBitmap = Bitmap.createBitmap(
                filteredMat.cols(),
                filteredMat.rows(),
                Bitmap.Config.ARGB_8888
            )
            Utils.matToBitmap(filteredMat, resultBitmap)

            return mapOf(
                "bytes" to resultBitmap.toPngBytes(),
                "detectedPixels" to Core.countNonZero(maskMat),
                "totalPixels" to maskMat.rows() * maskMat.cols()
            )
        } finally {
            rgbaMat.release()
            rgbMat.release()
            hsvMat.release()
            maskMat.release()
            filteredMat.release()
        }
    }

    private fun resolveDisplayName(call: MethodCall): String {
        val currentName = call.argument<String>("currentName")
        val path = call.argument<String>("path")
        val sourceUri = call.argument<String>("sourceUri")

        val candidates = mutableListOf<String?>()
        if (!sourceUri.isNullOrBlank()) {
            val uri = Uri.parse(sourceUri)
            candidates += readDisplayNameFromUri(uri)
            candidates += readVideoTitle(uri = uri, path = null)
        }
        if (!path.isNullOrBlank()) {
            candidates += File(path).name
            candidates += readVideoTitle(uri = null, path = path)
        }
        candidates += currentName

        return resolveDisplayNameFromCandidates(candidates)
    }

    private fun copyPickedVideoToCache(uri: Uri): Map<String, Any> {
        val displayName = resolveDisplayNameFromCandidates(
            listOf(
                readDisplayNameFromUri(uri),
                readVideoTitle(uri = uri, path = null),
                "selected_video_${System.currentTimeMillis()}.mp4"
            )
        )
        val cacheFolder = File(cacheDir, "selected_videos")
        if (!cacheFolder.exists()) {
            cacheFolder.mkdirs()
        }
        val outputFile = uniqueFile(cacheFolder, sanitizeFileName(displayName))

        contentResolver.openInputStream(uri)?.use { input ->
            BufferedInputStream(input).use { bufferedInput ->
                BufferedOutputStream(FileOutputStream(outputFile)).use { output ->
                    bufferedInput.copyTo(output)
                    output.flush()
                }
            }
        } ?: throw IOException("선택한 영상을 열지 못했습니다.")

        return mapOf(
            "path" to outputFile.absolutePath,
            "sourceUri" to uri.toString(),
            "displayName" to displayName,
            "cachedName" to outputFile.name
        )
    }

    private fun resolveDisplayNameFromCandidates(candidates: List<String?>): String {
        return candidates
            .mapNotNull { it?.trim() }
            .firstOrNull { it.isNotBlank() && !looksLikeProviderId(it) }
            ?: candidates.mapNotNull { it?.trim() }.firstOrNull { it.isNotBlank() }
            ?: "선택한 영상.mp4"
    }

    private fun readDisplayNameFromUri(uri: Uri): String? {
        val columns = arrayOf(
            OpenableColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.TITLE
        )
        for (column in columns) {
            try {
                contentResolver.query(uri, arrayOf(column), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(column)
                        if (index >= 0) {
                            val value = cursor.getString(index)
                            if (!value.isNullOrBlank()) {
                                return value
                            }
                        }
                    }
                }
            } catch (_: Throwable) {
                // Some providers reject individual columns. Try the next one.
            }
        }
        return null
    }

    private fun readVideoTitle(uri: Uri?, path: String?): String? {
        val retriever = MediaMetadataRetriever()
        return try {
            when {
                uri != null -> retriever.setDataSource(this, uri)
                !path.isNullOrBlank() -> retriever.setDataSource(path)
                else -> return null
            }
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
        } catch (_: Throwable) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun looksLikeProviderId(value: String): Boolean {
        val name = value.substringBeforeLast('.')
        return name.matches(Regex("\\d{8,}"))
    }

    private fun sanitizeFileName(value: String): String {
        val cleaned = value.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
        val fallback = cleaned.ifBlank { "selected_video.mp4" }
        return if (fallback.contains('.')) fallback else "$fallback.mp4"
    }

    private fun uniqueFile(folder: File, fileName: String): File {
        val dotIndex = fileName.lastIndexOf('.')
        val baseName = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
        val extension = if (dotIndex > 0) fileName.substring(dotIndex) else ""
        var candidate = File(folder, fileName)
        var index = 1
        while (candidate.exists()) {
            candidate = File(folder, "${baseName}_$index$extension")
            index++
        }
        return candidate
    }

    private fun computeDisplacement(call: MethodCall): Map<String, Any> {
        val videoPath = call.requiredArgument<String>("videoPath")
        val roiX = call.requiredDouble("roiX")
        val roiY = call.requiredDouble("roiY")
        val roiWidth = call.requiredDouble("roiWidth")
        val roiHeight = call.requiredDouble("roiHeight")
        val hMin = call.requiredDouble("hMin")
        val hMax = call.requiredDouble("hMax")
        val sMin = call.requiredDouble("sMin")
        val sMax = call.requiredDouble("sMax")
        val vMin = call.requiredDouble("vMin")
        val vMax = call.requiredDouble("vMax")
        val markerX = call.requiredDouble("markerX")
        val markerY = call.requiredDouble("markerY")
        val trackingBoxSize = call.requiredDouble("trackingBoxSize")
        val fps = call.requiredDouble("fps").takeIf { it > 0.0 } ?: 30.0

        val capture = VideoCapture(videoPath)
        if (!capture.isOpened) {
            throw IllegalStateException("영상을 열지 못했습니다.")
        }

        val frame = Mat()
        val positions = mutableListOf<Pair<Double, Double>>()
        var previousX = markerX
        var previousY = markerY
        var detectedFrameCount = 0
        var missedFrameCount = 0
        var processedFrameCount = 0

        try {
            val totalFrames = capture.get(Videoio.CAP_PROP_FRAME_COUNT).toInt()
            val maxFrames = if (totalFrames > 0) min(totalFrames, MODEL_INPUT_LENGTH) else MODEL_INPUT_LENGTH
            var frameIndex = 0
            sendDisplacementProgress(0, maxFrames, detectedFrameCount, missedFrameCount)

            while (frameIndex < maxFrames && capture.read(frame)) {
                if (!frame.empty()) {
                    processedFrameCount++
                    val frameWidth = frame.cols()
                    val frameHeight = frame.rows()
                    val roiLeft = (roiX * frameWidth).toInt().coerceIn(0, frameWidth - 1)
                    val roiTop = (roiY * frameHeight).toInt().coerceIn(0, frameHeight - 1)
                    val roiRight = ((roiX + roiWidth) * frameWidth).toInt().coerceIn(roiLeft + 1, frameWidth)
                    val roiBottom = ((roiY + roiHeight) * frameHeight).toInt().coerceIn(roiTop + 1, frameHeight)

                    val roiMat = frame.submat(roiTop, roiBottom, roiLeft, roiRight)
                    val roiPixelWidth = roiMat.cols()
                    val roiPixelHeight = roiMat.rows()

                    val halfBox = max(3.0, trackingBoxSize / 2.0)
                    val searchLeft = (previousX - halfBox).toInt().coerceIn(0, roiPixelWidth - 1)
                    val searchTop = (previousY - halfBox).toInt().coerceIn(0, roiPixelHeight - 1)
                    val searchRight = (previousX + halfBox).toInt().coerceIn(searchLeft + 1, roiPixelWidth)
                    val searchBottom = (previousY + halfBox).toInt().coerceIn(searchTop + 1, roiPixelHeight)
                    val searchMat = roiMat.submat(searchTop, searchBottom, searchLeft, searchRight)

                    try {
                        val searchDetection = detectMarkerCenter(
                            source = searchMat,
                            hMin = hMin,
                            hMax = hMax,
                            sMin = sMin,
                            sMax = sMax,
                            vMin = vMin,
                            vMax = vMax,
                        )
                        val roiDetection = searchDetection?.let {
                            Pair(searchLeft + it.first, searchTop + it.second)
                        } ?: detectMarkerCenter(
                            source = roiMat,
                            hMin = hMin,
                            hMax = hMax,
                            sMin = sMin,
                            sMax = sMax,
                            vMin = vMin,
                            vMax = vMax,
                        )

                        if (roiDetection != null) {
                            previousX = roiDetection.first
                            previousY = roiDetection.second
                            detectedFrameCount++
                            positions.add(Pair(previousX, previousY))
                        } else {
                            missedFrameCount++
                            if (positions.isNotEmpty()) {
                                positions.add(Pair(previousX, previousY))
                            }
                        }
                    } finally {
                        searchMat.release()
                        roiMat.release()
                    }
                    if (processedFrameCount % 10 == 0 || processedFrameCount == maxFrames) {
                        sendDisplacementProgress(
                            processedFrameCount,
                            maxFrames,
                            detectedFrameCount,
                            missedFrameCount
                        )
                    }
                }
                frameIndex++
            }
        } finally {
            capture.release()
            frame.release()
        }

        if (detectedFrameCount == 0) {
            throw IllegalStateException(
                "마커가 한 프레임도 검출되지 않았습니다. HSV 범위, 마커 색상, ROI, 마커 중심/박스 크기를 다시 확인해주세요."
            )
        }
        if (positions.isEmpty()) {
            throw IllegalStateException("마커 변위를 계산하지 못했습니다.")
        }

        val averageX = positions.map { it.first }.average()
        val averageY = positions.map { it.second }.average()
        val displacementX = positions.map { it.first - averageX }
        val displacementZ = positions.map { it.second - averageY }
        val modelInput = resizeSeries(displacementZ, MODEL_INPUT_LENGTH)
        val csvInfo = saveDisplacementsToCsv(displacementX, displacementZ, fps)
        val zStdDev = standardDeviation(displacementZ)
        sendDisplacementProgress(processedFrameCount, processedFrameCount, detectedFrameCount, missedFrameCount)

        return mapOf(
            "displacementZ" to modelInput,
            "rawLength" to processedFrameCount,
            "detectedFrameCount" to detectedFrameCount,
            "missedFrameCount" to missedFrameCount,
            "zStdDev" to zStdDev,
            "csvUri" to csvInfo.first,
            "csvDisplayName" to csvInfo.second
        )
    }

    private fun standardDeviation(values: List<Double>): Double {
        if (values.isEmpty()) {
            return 0.0
        }
        val average = values.average()
        val variance = values.map { (it - average) * (it - average) }.average()
        return sqrt(variance)
    }

    private fun detectMarkerCenter(
        source: Mat,
        hMin: Double,
        hMax: Double,
        sMin: Double,
        sMax: Double,
        vMin: Double,
        vMax: Double,
    ): Pair<Double, Double>? {
        detectMarkerCenterWithColor(source, Imgproc.COLOR_BGR2HSV, hMin, hMax, sMin, sMax, vMin, vMax)
            ?.let { return it }

        return detectMarkerCenterWithColor(source, Imgproc.COLOR_RGB2HSV, hMin, hMax, sMin, sMax, vMin, vMax)
    }

    private fun detectMarkerCenterWithColor(
        source: Mat,
        colorConversionCode: Int,
        hMin: Double,
        hMax: Double,
        sMin: Double,
        sMax: Double,
        vMin: Double,
        vMax: Double,
    ): Pair<Double, Double>? {
        val hsvMat = Mat()
        val mask = Mat()
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_ELLIPSE, Size(5.0, 5.0))

        return try {
            Imgproc.cvtColor(source, hsvMat, colorConversionCode)
            Core.inRange(
                hsvMat,
                Scalar(hMin, sMin, vMin),
                Scalar(hMax, sMax, vMax),
                mask
            )
            Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_OPEN, kernel)
            Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_CLOSE, kernel)

            val moments = Imgproc.moments(mask)
            if (moments.m00 == 0.0) {
                null
            } else {
                Pair(moments.m10 / moments.m00, moments.m01 / moments.m00)
            }
        } finally {
            hsvMat.release()
            mask.release()
            kernel.release()
        }
    }

    private fun saveDisplacementsToCsv(
        displacementX: List<Double>,
        displacementZ: List<Double>,
        fps: Double
    ): Pair<String, String> {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val displayName = "displacement_$timeStamp.csv"
        val csvText = buildString {
            append("# FPS: $fps\n")
            append("Frame,Time(s),DisplacementX(px),DisplacementZ(px)\n")
            displacementZ.forEachIndexed { index, z ->
                val timeInSeconds = index / fps
                val x = displacementX.getOrElse(index) { 0.0 }
                append("$index,$timeInSeconds,$x,$z\n")
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                put(MediaStore.Downloads.MIME_TYPE, "text/csv")
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/OpenCVDisplacement"
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("CSV 저장 위치를 만들지 못했습니다.")

            try {
                contentResolver.openOutputStream(uri)?.use { output ->
                    output.write(csvText.toByteArray(Charsets.UTF_8))
                } ?: throw IOException("CSV 출력 스트림을 열지 못했습니다.")

                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                return Pair(uri.toString(), "Downloads/OpenCVDisplacement/$displayName")
            } catch (error: Throwable) {
                contentResolver.delete(uri, null, null)
                throw error
            }
        }

        val publicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val appFolder = File(publicDir, "OpenCVDisplacement")
        if (!appFolder.exists()) {
            appFolder.mkdirs()
        }
        val csvFile = File(appFolder, displayName)
        csvFile.writeText(csvText, Charsets.UTF_8)
        return Pair(csvFile.toURI().toString(), csvFile.absolutePath)
    }

    private fun diagnose(call: MethodCall): Map<String, Any> {
        val inputData = call.requiredArgument<List<Number>>("displacementZ")
            .map { it.toFloat() }

        if (inputData.size != MODEL_INPUT_LENGTH) {
            throw IllegalArgumentException(
                "모델 입력 길이는 $MODEL_INPUT_LENGTH 이어야 합니다. 현재: ${inputData.size}"
            )
        }

        val modelFilePath = assetFilePath(this, MODEL_ASSET_NAME)
        val model = LiteModuleLoader.load(modelFilePath)
        val inputTensor = Tensor.fromBlob(
            inputData.toFloatArray(),
            longArrayOf(1, 1, MODEL_INPUT_LENGTH.toLong())
        )
        val logits = model.forward(IValue.from(inputTensor)).toTensor().dataAsFloatArray
        val probabilities = softmax(logits).map { it.toDouble() }

        return mapOf(
            "classLabels" to listOf("B", "H", "IR", "OR"),
            "probabilities" to probabilities,
            "logits" to logits.map { it.toDouble() },
            "modelName" to MODEL_ASSET_NAME
        )
    }

    private fun softmax(values: FloatArray): List<Float> {
        if (values.isEmpty()) {
            return emptyList()
        }
        val maxValue = values.maxOrNull() ?: 0f
        val expValues = values.map { kotlin.math.exp((it - maxValue).toDouble()) }
        val sumExp = expValues.sum()
        return expValues.map { (it / sumExp).toFloat() }
    }

    @Throws(IOException::class)
    private fun assetFilePath(context: Context, assetName: String): String {
        val file = File(context.filesDir, assetName)
        if (!file.exists() || file.length() == 0L) {
            context.assets.open(assetName).use { input ->
                FileOutputStream(file).use { output ->
                    val buffer = ByteArray(4 * 1024)
                    while (true) {
                        val bytesRead = input.read(buffer)
                        if (bytesRead == -1) {
                            break
                        }
                        output.write(buffer, 0, bytesRead)
                    }
                    output.flush()
                }
            }
        }
        return file.absolutePath
    }

    private fun resizeSeries(values: List<Double>, targetLength: Int): List<Double> {
        if (values.isEmpty()) {
            return List(targetLength) { 0.0 }
        }
        if (values.size == targetLength) {
            return values
        }
        if (values.size == 1) {
            return List(targetLength) { values.first() }
        }

        val lastSourceIndex = values.lastIndex.toDouble()
        val lastTargetIndex = (targetLength - 1).toDouble()
        return List(targetLength) { targetIndex ->
            val sourcePosition = targetIndex / lastTargetIndex * lastSourceIndex
            val leftIndex = sourcePosition.toInt().coerceIn(0, values.lastIndex)
            val rightIndex = min(leftIndex + 1, values.lastIndex)
            val ratio = sourcePosition - leftIndex
            values[leftIndex] * (1.0 - ratio) + values[rightIndex] * ratio
        }
    }

    private inline fun <reified T> MethodCall.requiredArgument(name: String): T {
        return argument<T>(name)
            ?: throw IllegalArgumentException("Missing MethodChannel argument: $name")
    }

    private fun MethodCall.requiredDouble(name: String): Double {
        val value = requiredArgument<Number>(name)
        return value.toDouble()
    }

    private fun Bitmap.toPngBytes(): ByteArray {
        val output = ByteArrayOutputStream()
        compress(Bitmap.CompressFormat.PNG, 100, output)
        return output.toByteArray()
    }
}
