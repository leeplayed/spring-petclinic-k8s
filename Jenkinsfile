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

        stage('Build JAR') {
            steps {
                echo ">>> 2. Maven Build..."

                sh """
                cd spring-petclinic-k8s
                docker run --rm \
                    -v \$PWD:/app \
                    -w /app \
                    maven:3.9.6-eclipse-temurin-17 \
                    mvn clean package -DskipTests
                """
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo ">>> 3. Build Docker Image..."

                sh """
                cd spring-petclinic-k8s
                docker build -t \$DOCKER_IMAGE:\$DOCKER_TAG .
                docker push \$DOCKER_IMAGE:\$DOCKER_TAG
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo ">>> 4. Deploy to Kubernetes..."
                sh """
                kubectl set image deployment/petclinic petclinic=\$DOCKER_IMAGE:\$DOCKER_TAG -n \$K8S_NAMESPACE
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
