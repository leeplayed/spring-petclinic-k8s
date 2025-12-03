pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: default
  containers:
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }

    environment {
        // [수정 필요] 본인 도커 허브 아이디
        DOCKER_REGISTRY_USER = 'leeplayed'
        
        IMAGE_NAME = 'spring-petclinic'
        APP_NAME = 'petclinic'
        
        DOCKER_TOKEN_ID = 'dockerhub-token'
        GIT_CRED_ID = 'github-ssh-key'
        
        GIT_REPO_URL = 'git@github.com:leeplayed/spring-petclinic-k8s.git'
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo '>>> Checking out Git Repository...'
                }
                git credentialsId: "${GIT_CRED_ID}", 
                    url: "${GIT_REPO_URL}", 
                    branch: 'main'
            }
        }

        stage('Build & Push Image') {
            steps {
                container('docker') {
                    script {
                        echo '>>> Building Docker Image...'
                        withCredentials([string(credentialsId: "${DOCKER_TOKEN_ID}", variable: 'DOCKER_TOKEN')]) {
                            sh 'echo $DOCKER_TOKEN | docker login -u $DOCKER_REGISTRY_USER --password-stdin'
                        }
                        
                        sh "docker build -t ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                        sh "docker build -t ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:latest ."
                        
                        sh "docker push ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                container('kubectl') {
                    script {
                        echo '>>> Deploying to Kubernetes...'
                        sh """
                        kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER} --local -o yaml > k8s/app/deployment_updated.yaml
                        """
                        
                        sh 'kubectl apply -f k8s/app/service.yaml'
                        sh 'kubectl apply -f k8s/app/ingress.yaml'
                        sh 'kubectl apply -f k8s/app/deployment_updated.yaml'
                        
                        sh "kubectl rollout status deployment/${APP_NAME}"
                    }
                }
            }
        }
    }
}
