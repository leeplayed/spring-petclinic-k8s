pipeline {
    agent {
        kubernetes {
            label 'kaniko-agent'        // Jenkins Pod Template label
            defaultContainer 'kubectl'  // 기본 실행 컨테이너
        }
    }

    environment {
        APP_NAMESPACE   = 'app'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'
    }

    stages {

        /*
         * 1) GitHub 코드 체크아웃
         */
        stage('Checkout Code') {
            steps {
                git credentialsId: 'github-ssh-key',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    branch: 'main'
            }
        }

        /*
         * 2) Kaniko로 이미지 빌드 + Docker Hub Push
         */
        stage('Build & Push Image (Kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                    echo ">>> Building & pushing Docker image using Kaniko..."
                    /kaniko/executor \
                        --dockerfile=Dockerfile \
                        --context=`pwd` \
                        --destination=${DOCKER_USER}/${IMAGE_NAME}:latest \
                        --destination=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        /*
         * 3) 쿠버네티스 배포
         */
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                    echo ">>> Deploying to Kubernetes..."

                    # 서비스/인그레스 적용
                    kubectl -n app apply -f k8s/app/service.yaml
                    kubectl -n app apply -f k8s/app/ingress.yaml

                    # 새 이미지로 Deployment 업데이트
                    kubectl -n app set image deployment/petclinic \
                        petclinic=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    # 롤아웃 상태 확인
                    kubectl -n app rollout status deployment/petclinic
                    '''
                }
            }
        }
    }
}
