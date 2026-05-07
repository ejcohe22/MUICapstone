# octave/Dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    octave \
    octave-signal \
    octave-control \
    octave-sockets \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

# non-root user
RUN useradd -m -u 1500 appuser && chown -R appuser:appuser /app
USER appuser

# startup.m is auto-loaded by octave, adds ji_math to path + prints help
CMD ["octave", "--no-gui", "--path", "/app/ji_math", "--eval", "source('/app/startup.m')", "--interactive"]
