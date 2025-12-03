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
                echo ">>> 1. Checkout SCM"
                checkout scm
            }
        }

        stage('Build JAR (Gradle)') {
            steps {
                echo ">>> 2. Gradle Build"
                sh """
                chmod +x ./gradlew
                ./gradlew clean build -x test
                """
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo ">>> 3. Build & Push Docker Image"
                sh """
                docker build -t \$DOCKER_IMAGE:\$DOCKER_TAG .
                docker push \$DOCKER_IMAGE:\$DOCKER_TAG
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo ">>> 4. Deploy to Kubernetes"
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
