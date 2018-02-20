#!/bin/bash
if hash npm 2>/dev/null; then
  npm i -g coffeescript && npm i -g browserify && npm i -g local-web-server
else
  echo "[FATAL] npm is not installed."
  exit 1
fi
