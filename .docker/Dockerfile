FROM node:17-alpine

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn

COPY . .