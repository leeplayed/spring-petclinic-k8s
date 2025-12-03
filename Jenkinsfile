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
                    url: 'https://github.com/leeplayed/spring-petclinic-k8s.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh """
                ./mvnw clean package -DskipTests
                """
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                docker build -t ${REGISTRY}/${IMAGE}:${TAG} .
                """
            }
        }

        stage('Docker Push') {
            steps {
                sh """
                docker push ${REGISTRY}/${IMAGE}:${TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                kubectl rollout restart deployment petclinic -n ${K8S_NAMESPACE}
                """
            }
        }

        /*
         * ===========================
         *   🔥 Node Disk Cleanup 
         *   containerd 이미지, 스냅샷 자동 삭제
         * ===========================
         */
        stage('Cleanup Node Disk') {
            steps {
                sh '''
                echo "=== [Cleanup] Containerd cleanup start ==="

                # crictl endpoint 설정 (없으면 생성)
                mkdir -p ~/.config/crictl
                cat <<EOF > ~/.config/crictl/config.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

                # containerd 사용하지 않는 이미지 삭제
                sudo crictl rmi --prune || true
                sudo crictl image prune || true

                # Committed snapshot 제거
                sudo ctr -n k8s.io snapshots ls | grep Committed | \
                awk '{print $1}' | xargs -I {} sudo ctr -n k8s.io snapshots rm {} || true

                echo "=== [Cleanup] Containerd cleanup finished ==="
                '''
            }
        }

    } // END stages

    /*
     * ===========================
     *  🔥 Build 후 Workspace Cleanup
     * =========================*
