# Multi-stage build to keep image light
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY ngnix.conf /etc/ngnix/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
