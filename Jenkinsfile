pipeline {
    // 1. Agent 정의: kaniko, jnlp 외에 maven 및 kubectl 컨테이너 추가
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
    # ⚠️ Docker 인증 Secret을 마운트하는 volumeMounts 추가
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
      readOnly: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
        ephemeral-storage: "2Gi"
  - name: maven // 2. Maven 빌드 환경 컨테이너 추가
    image: maven:3.9.6-eclipse-temurin-17 // Java 17 포함된 Maven 이미지
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "1000m"
        ephemeral-storage: "1Gi"
  - name: kubectl // 3. Kubernetes 배포를 위한 kubectl 컨테이너 추가
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
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
      secretName: dockertoken // Docker Hub 인증 Secret
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
                // ⬇️ kaniko 대신 maven 컨테이너에서 빌드 실행
                container('maven') {
                    sh "./mvnw clean package -DskipTests -Dcheckstyle.skip=true"
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                // ⬇️ Kaniko 컨테이너에서 이미지 빌드 및 푸시 실행
                container('kaniko') {
                    sh """
                    echo "===== Kaniko Build Start ====="
                    # --context \$WORKSPACE: 공유 워크스페이스를 Context로 사용
                    # --destination ${REGISTRY}/${IMAGE}:${TAG}: 환경 변수를 사용하여 태그
                    /kaniko/executor \
                      --context \$WORKSPACE \
                      --dockerfile Dockerfile \
                      --destination ${REGISTRY}/${IMAGE}:${TAG} \
                      --snapshot-mode=redo \
                      --cache=true \
                      --insecure-pull=false # 보안 강화를 위해 일반적으로 false 유지
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // ⬇️ kubectl 컨테이너에서 배포 실행
                container('kubectl') {
                    sh """
                    # ⚠️ 이 스테이지가 성공하려면 Jenkins Agent의 ServiceAccount에
                    # 해당 네임스페이스에 대한 kubectl 권한(RBAC)이 설정되어 있어야 합니다.
                    echo "===== Deployment Start ====="
                    
                    # 이미지 태그를 자동으로 업데이트하는 sed (선택 사항)
                    # sed -i "s|image: .*|image: ${REGISTRY}/${IMAGE}:${TAG}|g" k8s/deployment.yaml
                    
                    kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                    kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                    
                    # 롤아웃 재시작으로 새 이미지를 즉시 반영 (배포가 이미 존재할 경우)
                    kubectl rollout restart deployment petclinic -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment petclinic -n ${K8S_NAMESPACE} --timeout=5m
                    
                    echo "===== Deployment Finish ====="
                    """
                }
            }
        }

        // ⚠️ Cleanup Node Disk 스테이지는 일반적으로 Jenkins Agent에서 직접 실행하기 어렵고 위험합니다.
        // Node Disk 정리는 쿠버네티스 클러스터 관리 영역으로, 이 스테이지를 **삭제하거나**
        // 호스트 접근 권한이 있는 전용 특권 컨테이너에서 실행해야 합니다.
        // 일반적인 CI/CD 파이프라인에서는 이 단계를 **제거**하는 것을 권장합니다.

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
