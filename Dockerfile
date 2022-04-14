FROM node:lts-alpine3.14 AS build-web
ADD . /app
WORKDIR /app/web
# Build web
RUN yarn config set registry https://registry.npm.taobao.org/ && yarn && yarn build

# Build jar
FROM gradle:6.9.2-jdk8 AS build-env
ADD --chown=gradle:gradle . /app
WORKDIR /app
COPY --from=build-web /app/web/dist /app/src/main/resources/web
RUN \
    rm src/main/java/org/lightink/reader/ReaderUIApplication.kt; \
    gradle -b cli.gradle assemble --info;

#FROM openjdk:8-jdk-alpine
FROM openjdk:8
# Install base packages
RUN \
    # apk update; \
    # apk upgrade; \
    # Add CA certs tini tzdata
    #sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    #apk add --no-cache ca-certificates tini tzdata; \
    apt-get update && apt install -y ca-certificates tini tzdata; \
    update-ca-certificates; \
    # Clean APK cache
    rm -rf /var/cache/apk/*;

# 时区
ENV TZ=Asia/Shanghai

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo Asia/Shanghai > /etc/timdezone \
  && dpkg-reconfigure -f noninteractive tzdata

EXPOSE 8080
#ENTRYPOINT ["/sbin/tini", "--"]
ENTRYPOINT ["/usr/bin/tini", "--"]
# COPY --from=hengyunabc/arthas:latest /opt/arthas /opt/arthas
COPY --from=build-env /app/build/libs/app-1.9.0.jar /app/bin/reader.jar
CMD ["java", "-jar", "/app/bin/reader.jar" ]
