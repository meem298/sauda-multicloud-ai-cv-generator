#!/bin/bash
# Run this from the project root: bash start.sh
export PATH="/opt/homebrew/Cellar/node/25.9.0_3/bin:/opt/homebrew/bin:$PATH"
cd "$(dirname "$0")/backend"
node server.js
