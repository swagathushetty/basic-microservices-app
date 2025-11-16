FROM node:16-alpine

WORKDIR /app

COPY package.json ./

RUN npm install

COPY . .

# Doesn't actually expose (need -p flag)
EXPOSE 4001

CMD ["npm", "start"]