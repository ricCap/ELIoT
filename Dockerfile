FROM mhart/alpine-node-auto AS build
WORKDIR /src/app
ADD config/package.json .
ADD ./devices .
RUN npm install && rm package.json

FROM mhart/alpine-node:slim-12
WORKDIR /src/app
COPY --from=build /src/app .
EXPOSE 5683
ENTRYPOINT [ "node" ]
