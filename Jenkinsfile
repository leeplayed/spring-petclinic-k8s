pipeline {
    // 🔥 쿠버네티스 에이전트 쓰지 않고, 젠킨스 메인 파드에서 실행
    agent any

    environment {
        // ---- App / Docker 정보 ----
        APP_NAMESPACE   = 'default'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'

        // ---- Credentials ----
        DOCKER_TOKEN_ID = 'dockertoken'  // Docker Hub token (Secret text)
    }

    stages {

        /*----------------------------------
         * 1. 소스코드 체크아웃 (SCM에서)
         *----------------------------------*/
        stage('Checkout Code') {
            steps {
                echo '>>> 1. Checking out code from SCM...'
                // Job 설정에 있는 SCM 설정 그대로 사용
                checkout scm
            }
        }

        /*----------------------------------
         * 2. Docker 이미지 Build & Push
         *   - jenkins-xxx 파드 안에서 docker 사용
         *----------------------------------*/
        stage('Build & Push Image') {
            steps {
                script {
                    echo '>>> 2. Docker Login...'
                }

                withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                    sh '''
                        echo "$DOCKER_TOKEN" | docker login -u '"'"${DOCKER_USER}"'"' --password-stdin
                    '''
                }

                script {
                    echo '>>> 3. Building Docker Image...'
                }

                sh """
                    docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_USER}/${IMAGE_NAME}:latest
                """

                script {
                    echo '>>> 4. Pushing Docker Images...'
                }

                sh """
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        /*----------------------------------
         * 3. Kubernetes 배포
         *   - jenkins-xxx 파드 안에서 kubectl 사용
         *----------------------------------*/
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo ">>> 5. Deploying to Kubernetes..."
                }

                sh """
                    # 서비스 & 인그레스 적용
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml

                    # Deployment 적용
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml

                    # 새로 빌드한 이미지로 업데이트
                    kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \\
                        ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    # 롤링 업데이트 완료까지 대기
                    kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}
                """
            }
        }
    }
}
