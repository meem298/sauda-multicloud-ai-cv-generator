FROM node:20-alpine
WORKDIR /app
COPY agent/package*.json ./
RUN npm install --only=production && npm cache clean --force
COPY agent/backend ./backend
COPY agent/frontend ./frontend
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:3000/health || exit 1
CMD ["node", "backend/server.js"]
