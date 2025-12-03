pipeline {
    agent {
        kubernetes {
            label 'kaniko-build'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
  - name: jnlp
    image: jenkins/inbound-agent:3345.v03dee9b_f88fc-1
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
      readOnly: false
  nodeSelector:
    jenkins-node: "true"
  restartPolicy: Never
  volumes:
  - name: docker-config
    secret:
      secretName: dockertoken
      items:
      - key: .dockerconfigjson
        path: config.json
  - emptyDir:
      medium: ""
    name: workspace-volume
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
                container('jnlp') {
                    git branch: 'main',
                        url: 'https://github.com/leeplayed/spring-petclinic-k8s.git',
                        credentialsId: 'github-token'
                }
            }
        }

        stage('Maven Build') {
            steps {
                container('jnlp') {
                    sh "./mvnw clean package -DskipTests -Dcheckstyle.skip=true"
                }
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
                container('jnlp') {
                    sh """
                    echo "===== Kubernetes Deploy Start ====="
                    kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                    kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}

                    kubectl set image deployment/petclinic petclinic=${FULL_IMAGE} -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment/petclinic -n ${K8S_NAMESPACE}
                    echo "===== Kubernetes Deploy Complete ====="
                    """
                }
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
