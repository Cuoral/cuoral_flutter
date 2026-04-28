package com.cuoral.cuoral_flutter

import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import android.view.WindowManager
import java.io.File
import java.io.IOException

class ScreenRecorder(
    private val context: Context,
    private val resultCode: Int,
    private val data: Intent
) {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var outputFile: File? = null
    
    companion object {
        private const val VIDEO_FRAME_RATE = 30
        private const val VIDEO_BIT_RATE = 6000000
    }
    
    fun startRecording() {
        try {
            // Create output file
            val videoDir = File(context.filesDir, "cuoral_recordings")
            if (!videoDir.exists()) {
                videoDir.mkdirs()
            }
            outputFile = File(videoDir, "recording_${System.currentTimeMillis()}.mp4")
            
            // Get screen dimensions
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val metrics = DisplayMetrics()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.display?.getRealMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getRealMetrics(metrics)
            }
            
            val screenWidth = metrics.widthPixels
            val screenHeight = metrics.heightPixels
            val screenDensity = metrics.densityDpi
            
            // Initialize MediaRecorder
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }
            
            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setVideoSource(MediaRecorder.VideoSource.SURFACE)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setOutputFile(outputFile?.absolutePath)
                setVideoSize(screenWidth, screenHeight)
                setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setVideoEncodingBitRate(VIDEO_BIT_RATE)
                setVideoFrameRate(VIDEO_FRAME_RATE)
                
                try {
                    prepare()
                } catch (e: IOException) {
                    throw e
                }
            }
            
            // Get MediaProjection
            val projectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, data)
            
            // Register callback for Android 14+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                    override fun onStop() {
                        super.onStop()
                        if (isRecording) {
                            stopRecording()
                        }
                    }
                }, null)
            }
            
            // Create virtual display
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "CuoralScreenRecording",
                screenWidth,
                screenHeight,
                screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder?.surface,
                null,
                null
            )
            
            mediaRecorder?.start()
            isRecording = true
        } catch (e: Exception) {
            cleanup()
            throw e
        }
    }
    
    fun stopRecording(): String? {
        try {
            if (!isRecording) {
                return null
            }
            
            isRecording = false
            
            // Stop recording
            try {
                mediaRecorder?.stop()
            } catch (_: Exception) {
            }
            
            cleanup()
            
            return outputFile?.absolutePath
        } catch (_: Exception) {
            return null
        }
    }
    
    fun isRecording(): Boolean {
        return isRecording
    }
    
    private fun cleanup() {
        try {
            mediaRecorder?.reset()
            mediaRecorder?.release()
            mediaRecorder = null
            
            virtualDisplay?.release()
            virtualDisplay = null
            
            mediaProjection?.stop()
            mediaProjection = null
        } catch (_: Exception) {
        }
    }
}
