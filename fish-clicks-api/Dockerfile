# ---------- BUILD ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copiamos primero lo mínimo para aprovechar cache
COPY pom.xml ./
COPY mvnw ./
COPY .mvn .mvn

# Descarga dependencias (cache)
RUN ./mvnw -B -DskipTests dependency:go-offline

# Copiamos el resto y construimos
COPY src ./src
RUN ./mvnw -B -DskipTests clean package

# ---------- RUN ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copia el jar generado (Spring Boot)
COPY --from=build /app/target/*.jar app.jar

# Render inyecta PORT, así que lo usamos
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "java -jar app.jar --server.port=${PORT}"]