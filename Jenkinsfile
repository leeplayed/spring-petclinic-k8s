pipeline {
    agent {
        kubernetes {
            label 'kaniko-build'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    jenkins-node: "true"
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
        ephemeral-storage: "2Gi"
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
        ephemeral-storage: "1Gi"
  volumes:
  - name: docker-config
    secret:
      secretName: dockertoken
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY = "docker.io/leeplayed"
        IMAGE = "petclinic"
        TAG = "latest"
        K8S_NAMESPACE = "app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    credentialsId: 'github-ssh-key'
            }
        }

        stage('Maven Build') {
            steps {
                container('kaniko') {
                    sh """
                    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                    export PATH=\$JAVA_HOME/bin:\$PATH
                    ./mvnw clean package -DskipTests -Dcheckstyle.skip=true
                    """
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                container('kaniko') {
                    sh """
                    echo "===== Kaniko Build Start ====="
                    /kaniko/executor \
                      --context \$WORKSPACE \
                      --dockerfile Dockerfile \
                      --destination ${REGISTRY}/${IMAGE}:${TAG} \
                      --snapshot-mode=redo \
                      --cache=true
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kaniko') {
                    sh """
                    kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                    kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                    kubectl rollout restart deployment petclinic -n ${K8S_NAMESPACE}
                    """
                }
            }
        }

        stage('Cleanup Node Disk') {
            steps {
                container('kaniko') {
                    sh """
                    echo "=== [Cleanup] Containerd cleanup start ==="

                    mkdir -p ~/.config/crictl
                    cat <<EOF > ~/.config/crictl/config.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

                    sudo crictl rmi --prune || true
                    sudo crictl image prune || true

                    sudo ctr -n k8s.io snapshots ls | grep Committed | \
                      awk '{print \$1}' | xargs -I {} sudo ctr -n k8s.io snapshots rm {} || true

                    echo "=== [Cleanup] Finished ==="
                    """
                }
            }
        }

    } // stages

    post {
        success {
            echo "🎉 Build & Deploy Success!"
        }
        failure {
            echo "🔥 Build Failed! Check logs!"
        }
    }
}
