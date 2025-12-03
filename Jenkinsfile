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
    - name: docker
      image: docker:26.1.1-cli
      command: ['cat']
      tty: true
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock

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

        GIT_CRED_ID     = 'github-https-token'
        DOCKER_TOKEN_ID = 'dockertoken'
    }

    stages {

        /*----------------------------------
         * 1. Checkout Source (SCM handled)
         *----------------------------------*/
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        /*----------------------------------
         * 2. Docker Build & Push
         *----------------------------------*/
        stage('Build & Push Image') {
            steps {
                container('docker') {
                    withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                        sh """
                          echo \$DOCKER_TOKEN | docker login -u ${DOCKER_USER} --password-stdin
                        """
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

        /*----------------------------------
         * 3. Deploy to K8s
         *----------------------------------*/
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/service.yaml
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/ingress.yaml
                      kubectl -n ${APP_NAMESPACE} apply -f k8s/app/deployment.yaml
                      kubectl -n ${APP_NAMESPACE} set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                      kubectl -n ${APP_NAMESPACE} rollout status deployment/${APP_NAME}
                    """
                }
            }
        }
    }
}
