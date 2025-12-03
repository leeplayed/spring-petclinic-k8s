pipeline {
    agent {
        kubernetes {
            // 타임아웃 10분 설정
            activeDeadlineSeconds 600
            // [중요] 외부 템플릿(inheritFrom)을 쓰지 않고 직접 정의합니다.
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: default
  containers:
  # 1. Docker 빌드용 컨테이너 (호스트 도커 소켓 공유)
  - name: docker
    image: docker:latest
    command: ["cat"]
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock

  # 2. 쿠버네티스 배포용 컨테이너
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true

  volumes:
  # 호스트의 도커 데몬을 빌려 쓰기 위한 설정
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }

    environment {
        // [설정] 업로드해주신 파일 경로(k8s/app)에 맞춤
        APP_NAMESPACE = 'default'
        APP_NAME      = 'petclinic'
        IMAGE_NAME    = 'spring-petclinic'
        DOCKER_USER   = 'leeplayed'

        // 젠킨스 Credentials ID
        GIT_CRED_ID   = 'github-ssh-key'
        DOCKER_TOKEN_ID = 'dockerhub-token'
    }

    stages {
        stage('Checkout Code') {
            steps {
                script { echo '>>> 1. Checking out code...' }
                git credentialsId: "${GIT_CRED_ID}",
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    branch: 'main'
            }
        }

        stage('Build & Push Image') {
            steps {
                container('docker') {
                    script {
                        echo '>>> 2. Docker Login...'
                        withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                            sh 'echo $DOCKER_TOKEN | docker login -u $DOCKER_USER --password-stdin'
                        }

                        echo '>>> 3. Build Image...'
                        // Dockerfile이 있는 현재 위치(.)에서 빌드
                        sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                        sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:latest ."

                        echo '>>> 4. Push Image...'
                        sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        echo ">>> 5. Deploying to Kubernetes..."

                        // [중요] k8s/app 폴더 경로 반영
                        // 1) Service & Ingress 적용
                        sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml"
                        sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml"

                        // 2) Deployment 이미지 버전 업데이트 (롤링 배포 트리거)
                        // 먼저 원본 파일을 적용 (없을 경우를 대비해)
                        sh "kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml"

                        // 현재 빌드된 이미지 태그로 교체
                        sh """
                        kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \
                            ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER}
                        """

                        // 3) 배포 완료 대기
                        sh "kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}"
                    }
                }
            }
        }
    }
}
