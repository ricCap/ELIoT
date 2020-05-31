FROM mhart/alpine-node-auto

WORKDIR /src/app

ADD config/package.json .

RUN npm install \
  && rm package.json

ADD ./devices .

EXPOSE 5683

ENTRYPOINT [ "node" ]
