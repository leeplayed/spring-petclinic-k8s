pipeline {
    agent any

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

        stage('Docker Build') {
            steps {
                sh """
                echo "==== Docker Build Start ===="
                docker build -t ${REGISTRY}/${IMAGE}:${TAG} .
                """
            }
        }

        stage('Docker Push') {
            steps {
                sh """
                echo "==== Docker Push Start ===="
                docker push ${REGISTRY}/${IMAGE}:${TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                echo "==== K8s Deploy Start ===="
                kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                kubectl rollout restart deployment petclinic -n ${K8S_NAMESPACE}
                """
            }
        }

        stage('Cleanup Node Disk') {
            steps {
                sh """
                echo "=== [Cleanup] Containerd cleanup start ==="

                mkdir -p ~/.config/crictl
                cat <<EOF > ~/.config/crictl/config.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

                # Unused images cleanup
                sudo crictl rmi --prune || true
                sudo crictl image prune || true

                # Committed snapshot cleanup
                sudo ctr -n k8s.io snapshots ls | grep Committed | \
                awk '{print \$1}' | xargs -I {} sudo ctr -n k8s.io snapshots rm {} || true

                echo "=== [Cleanup] Finished ==="
                """
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
