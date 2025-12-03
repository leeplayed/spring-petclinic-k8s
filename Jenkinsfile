pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIAL = 'dockerhub-cred'
        GITHUB_CREDENTIAL = 'github-ssh-key'
        DOCKER_REPO = "leeplayed/spring-petclinic"
        K8S_NAMESPACE = "app"
        DEPLOYMENT_NAME = "petclinic"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo ">>> 1. Checkout from GitHub..."
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                        credentialsId: "${GITHUB_CREDENTIAL}"
                    ]]
                ])
            }
        }

        stage('Build JAR (Gradle)') {
            steps {
                echo ">>> 2. Gradle Build..."
                sh """
                docker run --rm \
                    -v ${WORKSPACE}:/workspace \
                    -w /workspace \
                    gradle:7.6.2-jdk17 \
                    gradle clean build -x test
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                echo ">>> 3. Building Docker Image..."
                script {
                    GIT_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    IMAGE_TAG = "${DOCKER_REPO}:${GIT_TAG}"
                    IMAGE_LATEST = "${DOCKER_REPO}:latest"
                }

                sh """
                docker build -t ${IMAGE_TAG} -t ${IMAGE_LATEST} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                echo ">>> 4. Push to DockerHub..."
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIAL}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                    echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                    docker push ${IMAGE_TAG}
                    docker push ${IMAGE_LATEST}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo ">>> 5. Deploying to Kubernetes..."

                sh """
                sed -i 's|image: .*|image: ${IMAGE_TAG}|g' k8s/deployment.yml

                kubectl apply -f k8s/ -n ${K8S_NAMESPACE}

                kubectl rollout restart deployment ${DEPLOYMENT_NAME} -n ${K8S_NAMESPACE}
                """
            }
        }
    }

    post {
        always {
            echo ">>> Pipeline Finished."
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
        success {
            echo "✅ Successfully deployed new version!"
        }
    }
}
