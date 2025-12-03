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
    command:
      - /kaniko/executor
    args:
      - "--dockerfile=/workspace/Dockerfile"
      - "--context=/workspace"
      - "--destination=leeplayed/spring-petclinic:latest"
      - "--destination=leeplayed/spring-petclinic:${BUILD_NUMBER}"
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

  - name: jnlp
    image: jenkins/inbound-agent
    args: ["\$(JENKINS_SECRET)", "\$(JENKINS_NAME)"]
    volumeMounts:
      - name: workspace-volume
        mountPath: /workspace

  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-config

  - name: workspace-volume
    emptyDir: {}
'''
        }
    }

    environment {
        APP_NAMESPACE   = 'app'
        APP_NAME        = 'petclinic'
        IMAGE_NAME      = 'spring-petclinic'
        DOCKER_USER     = 'leeplayed'

        // Jenkins Credentials ID
        GIT_CRED_ID     = 'github-ssh-key'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: "${GIT_CRED_ID}",
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git'

                // 소스를 Kaniko workspace로 복사
                sh 'cp -R * /workspace/'
            }
        }

        stage('Build & Push Image (KANIKO)') {
            steps {
                container('kaniko') {
                    sh 'echo ">>> Building & pushing Docker image using Kaniko..."'
                    sh 'ls -al /workspace'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                    echo ">>> Deploying to K8s..."

                    # 서비스 / 인그레스 적용
                    kubectl -n app apply -f k8s/app/service.yaml
                    kubectl -n app apply -f k8s/app/ingress.yaml

                    # 새 이미지로 업데이트
                    kubectl -n app set image deployment/petclinic \
                        petclinic=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    # 롤아웃 확인
                    kubectl -n app rollout status deployment/petclinic
                    '''
                }
            }
        }
    }
}
