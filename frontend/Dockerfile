FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
# Bake the git commit into the image. CI passes --build-arg GIT_SHA=<commit>;
# the app reads it from process.env.GIT_SHA and exposes it at /version.
ARG GIT_SHA=dev
ENV GIT_SHA=$GIT_SHA
EXPOSE 3000
CMD ["node", "src/server.js"]
