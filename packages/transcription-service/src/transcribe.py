#!/usr/bin/env python3
"""
Project Nexus Transcription Service
Whisper-based audio transcription service with REST API
"""

import os
import sys
import json
import time
import asyncio
import logging
from pathlib import Path
from typing import Dict, List, Optional, Union
from dataclasses import dataclass, asdict
from datetime import datetime

# FastAPI imports
from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Whisper and audio processing
import whisper
import torch
from pydub import AudioSegment
import tempfile

# Configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TranscriptionRequest:
    """Transcription request configuration"""
    language: str = "auto"
    model: str = "base"
    task: str = "transcribe"  # transcribe or translate
    temperature: float = 0.0
    no_speech_threshold: float = 0.6
    logprob_threshold: float = -1.0

@dataclass
class TranscriptionSegment:
    """Individual transcription segment with timing"""
    id: int
    seek: int
    start: float
    end: float
    text: str
    tokens: List[int]
    temperature: float
    avg_logprob: float
    compression_ratio: float
    no_speech_prob: float

@dataclass
class TranscriptionResult:
    """Complete transcription result"""
    text: str
    language: str
    segments: List[TranscriptionSegment]
    duration: float
    model: str
    processing_time: float
    created_at: str

class TranscriptionService:
    """Whisper-based transcription service"""
    
    def __init__(self):
        self.models = {}
        self.supported_models = ["tiny", "base", "small", "medium", "large"]
        self.supported_languages = [
            "auto", "en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar", "hi"
        ]
        self.jobs = {}  # In-memory job storage (use Redis in production)
        
        # Check for GPU availability
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {self.device}")
        
        # Load default model
        self.load_model("base")

    def load_model(self, model_name: str) -> None:
        """Load a Whisper model into memory"""
        if model_name not in self.supported_models:
            raise ValueError(f"Unsupported model: {model_name}")
        
        if model_name not in self.models:
            logger.info(f"Loading Whisper model: {model_name}")
            try:
                self.models[model_name] = whisper.load_model(model_name, device=self.device)
                logger.info(f"Successfully loaded model: {model_name}")
            except Exception as e:
                logger.error(f"Failed to load model {model_name}: {e}")
                raise

    def preprocess_audio(self, file_path: str) -> str:
        """Preprocess audio file for transcription"""
        try:
            # Load audio with pydub for format conversion if needed
            audio = AudioSegment.from_file(file_path)
            
            # Convert to wav format if needed
            if not file_path.lower().endswith('.wav'):
                wav_path = file_path.rsplit('.', 1)[0] + '_converted.wav'
                audio.export(wav_path, format="wav")
                return wav_path
            
            return file_path
        except Exception as e:
            logger.error(f"Audio preprocessing failed: {e}")
            raise

    async def transcribe_audio(
        self, 
        file_path: str, 
        config: TranscriptionRequest
    ) -> TranscriptionResult:
        """Transcribe audio file using Whisper"""
        start_time = time.time()
        
        try:
            # Load model if not already loaded
            if config.model not in self.models:
                self.load_model(config.model)
            
            model = self.models[config.model]
            
            # Preprocess audio
            processed_path = self.preprocess_audio(file_path)
            
            # Transcription options
            options = {
                "language": None if config.language == "auto" else config.language,
                "task": config.task,
                "temperature": config.temperature,
                "no_speech_threshold": config.no_speech_threshold,
                "logprob_threshold": config.logprob_threshold,
            }
            
            # Perform transcription
            logger.info(f"Starting transcription with model {config.model}")
            result = model.transcribe(processed_path, **options)
            
            # Calculate processing time
            processing_time = time.time() - start_time
            
            # Convert segments to our format
            segments = [
                TranscriptionSegment(
                    id=seg["id"],
                    seek=seg["seek"],
                    start=seg["start"],
                    end=seg["end"],
                    text=seg["text"],
                    tokens=seg["tokens"],
                    temperature=seg.get("temperature", 0.0),
                    avg_logprob=seg.get("avg_logprob", 0.0),
                    compression_ratio=seg.get("compression_ratio", 0.0),
                    no_speech_prob=seg.get("no_speech_prob", 0.0)
                )
                for seg in result["segments"]
            ]
            
            # Create result object
            transcription_result = TranscriptionResult(
                text=result["text"].strip(),
                language=result["language"],
                segments=segments,
                duration=len(result["segments"]) * 30 if result["segments"] else 0,  # Approximate
                model=config.model,
                processing_time=processing_time,
                created_at=datetime.utcnow().isoformat()
            )
            
            # Cleanup temporary files
            if processed_path != file_path and os.path.exists(processed_path):
                os.remove(processed_path)
            
            logger.info(f"Transcription completed in {processing_time:.2f}s")
            return transcription_result
            
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            raise

    def format_as_srt(self, result: TranscriptionResult) -> str:
        """Format transcription result as SRT subtitles"""
        srt_content = []
        
        for i, segment in enumerate(result.segments, 1):
            start_time = self._seconds_to_srt_time(segment.start)
            end_time = self._seconds_to_srt_time(segment.end)
            
            srt_content.append(f"{i}")
            srt_content.append(f"{start_time} --> {end_time}")
            srt_content.append(segment.text.strip())
            srt_content.append("")  # Empty line between segments
        
        return "\n".join(srt_content)

    def format_as_vtt(self, result: TranscriptionResult) -> str:
        """Format transcription result as WebVTT"""
        vtt_content = ["WEBVTT", ""]
        
        for segment in result.segments:
            start_time = self._seconds_to_vtt_time(segment.start)
            end_time = self._seconds_to_vtt_time(segment.end)
            
            vtt_content.append(f"{start_time} --> {end_time}")
            vtt_content.append(segment.text.strip())
            vtt_content.append("")
        
        return "\n".join(vtt_content)

    def _seconds_to_srt_time(self, seconds: float) -> str:
        """Convert seconds to SRT time format (HH:MM:SS,mmm)"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        millis = int((seconds - int(seconds)) * 1000)
        return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"

    def _seconds_to_vtt_time(self, seconds: float) -> str:
        """Convert seconds to WebVTT time format (HH:MM:SS.mmm)"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        millis = int((seconds - int(seconds)) * 1000)
        return f"{hours:02d}:{minutes:02d}:{secs:02d}.{millis:03d}"

# Initialize service
transcription_service = TranscriptionService()

# FastAPI app
app = FastAPI(
    title="Project Nexus Transcription Service",
    description="Whisper-based audio transcription service",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "device": transcription_service.device,
        "loaded_models": list(transcription_service.models.keys()),
        "supported_models": transcription_service.supported_models,
        "supported_languages": transcription_service.supported_languages,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/transcribe")
async def transcribe_endpoint(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language: str = "auto",
    model: str = "base",
    task: str = "transcribe",
    format: str = "json"
):
    """Transcribe uploaded audio file"""
    
    # Validate inputs
    if model not in transcription_service.supported_models:
        raise HTTPException(status_code=400, detail=f"Unsupported model: {model}")
    
    if language not in transcription_service.supported_languages:
        raise HTTPException(status_code=400, detail=f"Unsupported language: {language}")
    
    if task not in ["transcribe", "translate"]:
        raise HTTPException(status_code=400, detail=f"Unsupported task: {task}")
    
    # Save uploaded file
    try:
        suffix = Path(file.filename).suffix if file.filename else ".wav"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save file: {e}")
    
    try:
        # Create transcription request
        config = TranscriptionRequest(
            language=language,
            model=model,
            task=task
        )
        
        # Perform transcription
        result = await transcription_service.transcribe_audio(tmp_path, config)
        
        # Format response based on requested format
        if format == "srt":
            formatted_result = transcription_service.format_as_srt(result)
            return JSONResponse(
                content={"text": formatted_result, "format": "srt"},
                headers={"Content-Type": "application/json"}
            )
        elif format == "vtt":
            formatted_result = transcription_service.format_as_vtt(result)
            return JSONResponse(
                content={"text": formatted_result, "format": "vtt"},
                headers={"Content-Type": "application/json"}
            )
        elif format == "text":
            return {"text": result.text}
        else:
            # Return full JSON result
            return asdict(result)
    
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {e}")
    
    finally:
        # Cleanup temporary file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

@app.get("/models")
async def list_models():
    """List available models"""
    models_info = []
    for model_name in transcription_service.supported_models:
        models_info.append({
            "name": model_name,
            "loaded": model_name in transcription_service.models,
            "description": f"Whisper {model_name} model"
        })
    return {"models": models_info}

@app.get("/languages")
async def list_languages():
    """List supported languages"""
    return {
        "languages": [
            {"code": "auto", "name": "Auto-detect"},
            {"code": "en", "name": "English"},
            {"code": "es", "name": "Spanish"},
            {"code": "fr", "name": "French"},
            {"code": "de", "name": "German"},
            {"code": "it", "name": "Italian"},
            {"code": "pt", "name": "Portuguese"},
            {"code": "ru", "name": "Russian"},
            {"code": "ja", "name": "Japanese"},
            {"code": "ko", "name": "Korean"},
            {"code": "zh", "name": "Chinese"},
            {"code": "ar", "name": "Arabic"},
            {"code": "hi", "name": "Hindi"}
        ]
    }

if __name__ == "__main__":
    # Run the server
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    uvicorn.run(
        "transcribe:app",
        host=host,
        port=port,
        reload=os.getenv("NODE_ENV") == "development",
        log_level="info"
    )