pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "leeplayed/spring-petclinic"
        DOCKER_TAG = "${BUILD_NUMBER}"
        K8S_NAMESPACE = "app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo ">>> 1. Checking out code from SCM..."
                checkout scm
            }
        }

        stage('Check Workspace') {
            steps {
                echo ">>> Checking Workspace Structure..."
                sh "pwd"
                sh "ls -al"
                sh "find . -maxdepth 3 -type f -name pom.xml"
            }
        }

        stage('Build JAR') {
            steps {
                echo ">>> 2. Maven Build..."

                sh """
                # 여기 결과 보고 cd 경로 수정 예정
                docker run --rm \
                    -v \$PWD:/app \
                    -w /app \
                    maven:3.9.6-eclipse-temurin-17 \
                    mvn clean package -DskipTests
                """
            }
        }
    }

    post {
        always {
            echo ">>> Pipeline Finished."
        }
    }
}
