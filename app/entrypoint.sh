#!/bin/bash
set -e
python3 -m pip install --upgrade pip
python3 -m pip install -e .
python3 -m gunicorn fastapi_app:app
