# ============================================================================
# DOCKERFILE FOR CUSTOM MODEL INFERENCE
# Build: docker build -t your-registry/model-inference:latest .
# Run:   docker run -p 8000:8000 your-registry/model-inference:latest
# ============================================================================
# Use Python slim image as base
FROM python:3.10-slim
# Set working directory
WORKDIR /app
# Install system dependencies
RUN apt-get update && apt-get install -y octave octave-control octave-signal curl wget git build-essential && rm -rf /var/lib/apt/lists/* && apt-get clean
# Create non-root user for security
RUN useradd -m -u 1000 appuser
# Copy requirements first (for Docker layer caching)
COPY requirements.txt .
# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
# Copy application code
COPY server.py .
COPY model/ ./model/
# Copy entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
# Change ownership to non-root user
RUN chown -R appuser:appuser /app
# Switch to non-root user
USER appuser
# Expose port
EXPOSE 8000
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
# Run application
CMD ["./entrypoint.sh"]
# FROM python:3.10-slim
# WORKDIR /app
# # Build stage
# FROM python:3.10 as builder
# WORKDIR /app
# COPY requirements.txt .
# RUN pip install --user --no-cache-dir -r requirements.txt
# # Final stage
# FROM python:3.10-slim
# WORKDIR /app
# # Copy Python dependencies from builder
# COPY --from=builder /root/.local /root/.local
# ENV PATH=/root/.local/bin:$PATH
# COPY server.py .
# COPY model/ ./model/
# EXPOSE 8000
# CMD ["python", "server.py"]
