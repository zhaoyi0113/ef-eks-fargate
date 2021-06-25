FROM node:14

WORKDIR /usr/src

COPY . .

RUN yarn install --frozen-lockfile

EXPOSE 8083

CMD [ "node", "index.js" ]
