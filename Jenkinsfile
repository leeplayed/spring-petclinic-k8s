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

    # 🔥 꼭 필요한 JNLP Agent (SCM 방식은 필수)
    - name: jnlp
      image: jenkins/inbound-agent:latest
      tty: true

    # Docker CLI
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

        DOCKER_TOKEN_ID = 'dockertoken'
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm   // SCM 방식 필수
            }
        }

        stage('Build & Push Image') {
            steps {
                container('docker') {
                    withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                        sh 'echo $DOCKER_TOKEN | docker login -u ${DOCKER_USER} --password-stdin'
                    }

                    sh """
                        docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .
                        docker tag ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_USER}/${IMAGE_NAME}:latest
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml

                      kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} \
                      ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                      kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}
                    """
                }
            }
        }
    }
}
