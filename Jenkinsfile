pipeline {

    agent {
        kubernetes {
            inheritFrom 'kaniko-agent'
        }
    }

    environment {
        APP_NAMESPACE = 'app'
        APP_NAME      = 'petclinic'
        IMAGE_NAME    = 'spring-petclinic'
        DOCKER_USER   = 'leeplayed'
        GIT_CRED_ID   = 'github-ssh-key'    // GitHub SSH Key
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: "${GIT_CRED_ID}",
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    branch: 'main'
            }
        }

        stage('Build & Push Image (Kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                    echo ">>> Building & pushing Docker image using Kaniko..."

                    /kaniko/executor \
                        --dockerfile=./Dockerfile \
                        --context=$(pwd) \
                        --destination=${DOCKER_USER}/${IMAGE_NAME}:latest \
                        --destination=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                    echo ">>> Deploying to Kubernetes ..."

                    # Service & Ingress 적용
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml

                    # 이미지 업데이트
                    kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    # 롤아웃 확인
                    kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}
                    '''
                }
            }
        }
    }
}
