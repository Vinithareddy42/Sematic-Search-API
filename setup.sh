#!/usr/bin/env bash
set -e

echo "[setup] Creating/activating virtualenv..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

echo "[setup] Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

echo "[setup] Ensuring .env exists..."
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  echo "[setup] Created .env from .env.example (edit it to add OPENAI_API_KEY etc.)."
fi

echo "[setup] Building vector index (Chroma)..."
python -m scripts.build_index

echo "[setup] Starting FastAPI with Uvicorn on http://localhost:8000 ..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

