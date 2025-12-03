pipeline {
    agent any

    environment {
        // ---- App / Docker 정보 ----
        APP_NAMESPACE   = 'default'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'

        // ---- Credentials ----
        GIT_CRED_ID     = 'github-ssh-key'
        DOCKER_TOKEN_ID = 'dockertoken'
    }

    stages {

        /*----------------------------------
         * 1. 소스코드 체크아웃
         *----------------------------------*/
        stage('Checkout Code') {
            steps {
                script {
                    echo '>>> 1. Checking out code...'
                }

                git credentialsId: "${GIT_CRED_ID}",
                    url: "https://github.com/leeplayed/spring-petclinic-k8s.git",
                    branch: "main"
            }
        }

        /*----------------------------------
         * 2. Docker 이미지 Build & Push
         *----------------------------------*/
        stage('Build & Push Image') {
            steps {
                script {
                    echo '>>> 2. Docker Login...'
                }

                withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                    sh """
                        echo \$DOCKER_TOKEN | docker login -u ${DOCKER_USER} --password-stdin
                    """
                }

                script {
                    echo '>>> 3. Building Docker Image...'
                }

                sh """
                    docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .
                    docker build -t ${DOCKER_USER}/${IMAGE_NAME}:latest .
                """

                script {
                    echo '>>> 4. Pushing Docker Image...'
                }

                sh """
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        /*----------------------------------
         * 3. Kubernetes 배포
         *----------------------------------*/
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo '>>> 5. Deploying to Kubernetes...'
                }

                // 1) Service & Ingress 적용
                sh """
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml
                """

                // 2) Deployment 적용
                sh """
                    kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml
                """

                // 3) 이미지 업데이트 → 롤링 배포 트리거
                sh """
                    kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                """

                // 4) 배포 완료될 때까지 대기
                sh """
                    kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}
                """
            }
        }
    }
}
