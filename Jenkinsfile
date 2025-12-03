pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "leeplayed/petclinic"
        DOCKER_TAG = "latest"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo ">>> 1. Checking out GitHub repository..."
                checkout scm
            }
        }

        stage('Build & Push Image') {
            steps {
                echo ">>> 2. Building Docker Image & Push to Docker Hub..."

                withCredentials([string(credentialsId: 'dockertoken', variable: 'DOCKER_TOKEN')]) {
                    sh '''
                        echo ">>> Docker Login..."
                        echo $DOCKER_TOKEN | docker login -u "leeplayed" --password-stdin

                        echo ">>> Building Docker Image..."
                        docker build -t $DOCKER_IMAGE:$DOCKER_TAG .

                        echo ">>> Pushing to Docker Hub..."
                        docker push $DOCKER_IMAGE:$DOCKER_TAG

                        echo ">>> Docker Logout..."
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo ">>> 3. Deploying to Kubernetes..."

                sh '''
                    echo ">>> Applying Kubernetes manifests..."
                    kubectl apply -f k8s/app/
                '''
            }
        }
    }

    post {
        success {
            echo ">>> Pipeline Completed Successfully!"
        }
        failure {
            echo ">>> Pipeline Failed!"
        }
    }
}
