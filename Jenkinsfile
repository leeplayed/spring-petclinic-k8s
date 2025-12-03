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
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args:
    - "--dockerfile=/workspace/Dockerfile"
    - "--context=/workspace"
    - "--destination=leeplayed/spring-petclinic:latest"
    - "--destination=leeplayed/spring-petclinic:${BUILD_NUMBER}"
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-config
'''
        }
    }

    environment {
        APP_NAMESPACE   = 'app'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: 'github-ssh-key',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    branch: 'main'
            }
        }

        stage('Build & Push Image (KANIKO)') {
            steps {
                container('kaniko') {
                    sh 'echo ">>> Building & pushing Docker image using Kaniko..."'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
