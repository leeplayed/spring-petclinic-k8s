pipeline {
    agent {
        kubernetes {
            label 'kaniko-build'
            defaultContainer 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
  volumes:
  - name: docker-config
    secret:
      secretName: dockerhub-secret
      items:
      - key: .dockerconfigjson
        path: config.json
"""
        }
    }

    environment {
        REGISTRY = "docker.io/leeplayed"
        IMAGE = "petclinic"
        TAG = "latest"
        K8S_NAMESPACE = "app"
        FULL_IMAGE = "${REGISTRY}/${IMAGE}:${TAG}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh """
                ./mvnw clean package -DskipTests -Dcheckstyle.skip=true
                """
            }
        }

        stage('Build & Push with Kaniko') {
            steps {
                container('kaniko') {
                    sh """
                    echo "===== Kaniko Build Start ====="

                    /kaniko/executor \
                        --context `pwd` \
                        --dockerfile Dockerfile \
                        --destination ${FULL_IMAGE} \
                        --snapshotMode=redo \
                        --cache=true

                    echo "===== Kaniko Build End ====="
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                echo "===== Kubernetes Deploy Start ====="
                kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}

                # Deployment 이미지 자동 업데이트
                kubectl set image deployment/petclinic petclinic=${FULL_IMAGE} -n ${K8S_NAMESPACE}

                # 롤링 업데이트 대기
                kubectl rollout status deployment/petclinic -n ${K8S_NAMESPACE}
                echo "===== Kubernetes Deploy Complete ====="
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy Success!"
        }
        failure {
            echo "🔥 Build Failed! Check logs!"
        }
    }

}
