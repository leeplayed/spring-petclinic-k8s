###############################
# 1) Build Stage
###############################
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /build

# 의존성 캐싱 (빌드 속도 빠르게 하기 위해)
COPY pom.xml .
RUN mvn dependency:go-offline

# 전체 소스 복사 후 빌드
COPY . .
RUN mvn clean package -DskipTests


###############################
# 2) Runtime Stage
###############################
FROM eclipse-temurin:17-jdk
WORKDIR /app

# build 단계에서 생성된 jar 파일 복사
COPY --from=builder /build/target/*.jar app.jar

# Spring Boot 기본 포트
EXPOSE 8080

# 실행
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
