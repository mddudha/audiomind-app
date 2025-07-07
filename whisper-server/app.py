from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from faster_whisper import WhisperModel
import tempfile

app = FastAPI()
model = WhisperModel("tiny", compute_type="float32")

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):  # 👈 File(...) means REQUIRED
    try:
        contents = await file.read()
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp:
            temp.write(contents)
            temp.flush()

            segments, _ = model.transcribe(temp.name)
            text = "".join(segment.text for segment in segments)
            return {"transcript": text}
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})
