pipeline {
    // Kubernetes Pod Template을 Agent로 사용
    agent {
        kubernetes {
            label 'kaniko-build'
            defaultContainer 'jnlp' // 기본 실행 컨테이너
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: kaniko
spec:
  # 빌드가 특정 노드에서 실행되도록 노드 셀렉터 설정
  nodeSelector:
    jenkins-node: "true"

  containers:

  # 1. Kaniko 컨테이너 — Docker build & push
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
      readOnly: true
    - name: workspace-volume
      mountPath: /home/jenkins/agent/workspace/
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
        ephemeral-storage: "2Gi"

  # 2. Maven 컨테이너 — Java build
  - name: maven
    image: maven:3.9.6-eclipse-temurin-17
    command: ["cat"]
    tty: true
    env:
    - name: JAVA_HOME
      value: /usr/local/openjdk-17
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent/workspace/
    resources:
      requests:
        memory: "1Gi"
        cpu: "1000m"
        ephemeral-storage: "1Gi"

  # 3. Kubectl 컨테이너 — Kubernetes deploy
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent/workspace/
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"

  # 4. JNLP — Jenkins agent container (필수)
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
        ephemeral-storage: "1Gi"

  volumes:
  # Docker Hub 인증을 위한 Secret 볼륨 마운트
  - name: docker-config
    secret:
      secretName: dockertoken
  # 컨테이너 간 작업 공간 공유를 위한 EmptyDir 볼륨
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    // ⚠️ tools { jdk null } 블록이 제거되었습니다.

    // 환경 변수 정의
    environment {
        REGISTRY = "docker.io/leeplayed"
        IMAGE = "petclinic"
        TAG = "${env.BUILD_NUMBER}"  // 이미지 태그를 빌드 번호로 설정
        K8S_NAMESPACE = "app"
    }

    stages {

        stage('Checkout') {
            steps {
                // SCM에서 코드 체크아웃
                git branch: 'main',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    credentialsId: 'github-ssh-key'
            }
        }

        stage('Maven Build') {
            steps {
                // Maven 컨테이너에서 Java 빌드 실행
                container('maven') {
                    sh """
                    ./mvnw clean package -DskipTests -Dcheckstyle.skip=true
                    """
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                // Kaniko 컨테이너에서 Docker 이미지 빌드 및 푸시
                container('kaniko') {
                    sh """
                    echo "===== Kaniko Build Start: ${REGISTRY}/${IMAGE}:${TAG} ====="
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
                // Kubectl 컨테이너에서 배포 실행
                container('kubectl') {
                    sh """
                    echo "🔄 Updating Deployment Image..."
                    kubectl set image deployment/petclinic petclinic-container=${REGISTRY}/${IMAGE}:${TAG} -n ${K8S_NAMESPACE}

                    echo "⏳ Waiting for rollout..."
                    kubectl rollout status deployment/petclinic -n ${K8S_NAMESPACE} --timeout=5m
                    """
                }
            }
        }
    }

    // 후처리 작업 (성공/실패 알림)
    post {
        success {
            echo "🎉 SUCCESS: Build & Deploy Completed!"
            echo "➡️ Image: ${REGISTRY}/${IMAGE}:${TAG}"
        }
        failure {
            echo "🔥 FAILED: Check the Jenkins logs!"
        }
    }
}
