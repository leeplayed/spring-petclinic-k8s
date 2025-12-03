pipeline {
    agent {
        kubernetes {
            label "petclinic-agent"
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins/agent: "true"
spec:
  serviceAccountName: default

  containers:

  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
      - /kaniko/executor
    args:
      - --dockerfile=/workspace/source/Dockerfile
      - --context=/workspace/source
      - --destination=leeplayed/spring-petclinic:\${BUILD_NUMBER}
      - --destination=leeplayed/spring-petclinic:latest
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker/
      - name: workspace-volume
        mountPath: /workspace

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    volumeMounts:
      - name: workspace-volume
        mountPath: /workspace

  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-config

  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    environment {
        APP_NAMESPACE = 'app'
        APP_NAME      = 'petclinic'
        IMAGE_NAME    = 'spring-petclinic'
        DOCKER_USER   = 'leeplayed'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-ssh-key',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git'

                sh 'mkdir -p /workspace/source'
                sh 'cp -R * /workspace/source/'
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {
                    sh 'echo ">>> Building & pushing Docker image using Kaniko..."'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                    kubectl -n app apply -f k8s/app/service.yaml
                    kubectl -n app apply -f k8s/app/ingress.yaml
                    kubectl -n app set image deployment/petclinic petclinic=${DOCKER_USER}/${IMAGE_NAME}:\${BUILD_NUMBER}
                    kubectl -n app rollout status deployment/petclinic
                    """
                }
            }
        }
    }
}
