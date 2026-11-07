FROM node:26-alpine3.23 AS build
WORKDIR /app
COPY package.json .
RUN npm install --omit=dev
COPY . .

FROM node:26-alpine3.23
WORKDIR /app
COPY --from=build /app .
USER node
EXPOSE 3000
CMD ["node", "server.js"]