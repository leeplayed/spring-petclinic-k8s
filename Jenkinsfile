pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins-agent: "true"
spec:
  serviceAccountName: default

  containers:
    # Docker CLI (host docker.sock 사용)
    - name: docker
      image: docker:26.1.1-cli
      command: ['cat']
      tty: true
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock

    # kubectl
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ['cat']
      tty: true

  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
"""
        }
    }

    environment {
        APP_NAMESPACE   = 'default'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'

        GIT_CRED_ID     = 'github-https-token'   // ← HTTPS token 권장
        DOCKER_TOKEN_ID = 'dockertoken'
    }

    stages {

        /*----------------------------------
         * 1. GitHub Checkout (SCM에서 받아옴)
         *----------------------------------*/
        stage('Checkout Code') {
            steps {
                script { echo ">>> 1. Checking out source (SCM provided)..." }
                checkout scm
            }
        }

        /*----------------------------------
         * 2. Docker 이미지 Build & Push
         *----------------------------------*/
        stage('Build & Push Image') {
            steps {
                container('docker') {
                    script { echo ">>> 2. Docker Login..." }

                    withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                        sh 'echo $DOCKER_TOKEN | docker login -u ${DOCKER_USER} --password-stdin'
                    }

                    script { echo ">>> 3. Building Docker Image..." }

                    sh """
                        docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_USER}/${IMAGE_NAME}:latest
                    """

                    script { echo ">>> 4. Pushing Docker Images..." }

                    sh """
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        /*----------------------------------
         * 3. Kubernetes 배포
         *----------------------------------*/
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script { echo ">>> 5. Deploying to Kubernetes..." }

                    // Service & Ingress 반영
                    sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml"
                    sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml"

                    // Deployment
                    sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml"

                    // 이미지 업데이트
                    sh """
                        kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \
                        ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """

                    // 롤링 업데이트 완료될 때까지 대기
                    sh "kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}"
                }
            }
        }
    }
}
