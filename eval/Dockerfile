# eval/Dockerfile
FROM node:22-slim

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Non-root user for extra safety
RUN useradd -m evaluser

# Create writable .claude directory structure
RUN mkdir -p /home/evaluser/.claude/projects && \
    chown -R evaluser:evaluser /home/evaluser/.claude

# Create entrypoint script
COPY --chown=evaluser:evaluser entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER evaluser
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]