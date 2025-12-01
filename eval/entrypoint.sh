#!/bin/bash
set -e

# Copy authentication from host .claude (mounted to /host-claude)
if [ -d "/host-claude/session-env" ]; then
  cp -r /host-claude/session-env /home/evaluser/.claude/
fi

if [ -f "/host-claude/settings.json" ]; then
  cp /host-claude/settings.json /home/evaluser/.claude/
fi

# Execute the command passed to docker run
exec "$@"
