# Video Saver backend: Node.js + yt-dlp for Railway
FROM node:20-slim

# Install yt-dlp + python3 (some envs need python3 for yt-dlp)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    python3-minimal \
    && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod +x /usr/local/bin/yt-dlp \
    && apt-get remove -y curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY server.js ./

# Railway sets PORT
ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]
