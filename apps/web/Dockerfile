FROM node:24-alpine AS build
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
ARG VITE_KRATOS_PUBLIC_URL=http://localhost:4433
ARG VITE_BRIDGE_URL=http://localhost:8081
ENV VITE_KRATOS_PUBLIC_URL=$VITE_KRATOS_PUBLIC_URL
ENV VITE_BRIDGE_URL=$VITE_BRIDGE_URL
RUN pnpm build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
