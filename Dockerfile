FROM maven:3.9-eclipse-temurin-21

WORKDIR /app

COPY backend/pom.xml ./pom.xml
COPY backend/src ./src

RUN mvn -DskipTests compile

EXPOSE 7001

CMD ["mvn", "-q", "-DskipTests", "exec:java"]
