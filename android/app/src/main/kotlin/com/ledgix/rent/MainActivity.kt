package com.ledgix.rent

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // On-device text recognition for document scanning (Google ML Kit).
        // "recognize" {path} -> [{text, left, top, right, bottom}] in image pixels.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ledgix/ocr").setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_args", "path is required", null)
                return@setMethodCallHandler
            }
            try {
                val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                recognizer.process(image)
                    .addOnSuccessListener { text ->
                        val lines = text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                            val b = line.boundingBox ?: return@mapNotNull null
                            mapOf(
                                "text" to line.text,
                                "left" to b.left.toDouble(),
                                "top" to b.top.toDouble(),
                                "right" to b.right.toDouble(),
                                "bottom" to b.bottom.toDouble(),
                            )
                        }
                        recognizer.close()
                        result.success(lines)
                    }
                    .addOnFailureListener { e ->
                        recognizer.close()
                        result.error("ocr_failed", e.message, null)
                    }
            } catch (e: Exception) {
                result.error("ocr_failed", e.message, null)
            }
        }
    }
}
