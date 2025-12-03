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
    - "--dockerfile=Dockerfile"
    - "--context=./"
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
                    sh '''
                    echo ">>> Deploying to K8s..."
                    kubectl -n app apply -f k8s/app/service.yaml
                    kubectl -n app apply -f k8s/app/ingress.yaml
                    
                    kubectl -n app set image deployment/petclinic \
                        petclinic=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    kubectl -n app rollout status deployment/petclinic
                    '''
                }
            }
        }
    }
}
