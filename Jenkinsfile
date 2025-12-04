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
    jenkins: kaniko-build
spec:
  # Pod 레벨의 securityContext를 제거하거나, 'runAsUser: 0'으로 변경합니다.
  # 여기서는 권한 충돌을 피하기 위해 Pod 레벨의 securityContext를 제거합니다.
  # securityContext:
  #   runAsUser: 1000
  #   fsGroup: 1000
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
    - key: "node.kubernetes.io/disk-pressure"
      operator: "Exists"
      effect: "NoSchedule"
  containers:
    # 1. Kaniko 컨테이너: 도커 이미지 빌드 및 레지스트리 푸시 담당 (권한 문제 해결을 위해 루트로 실행)
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["cat"]
      tty: true
      # Kaniko 컨테이너에만 루트 권한을 부여
      securityContext:
        runAsUser: 0
      volumeMounts:
        # Secret 키(.dockerconfigjson)를 Kaniko가 찾는 파일명(config.json)으로 직접 마운트
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: .dockerconfigjson
          readOnly: true
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

    # 2. Maven 컨테이너: Java/Spring Boot 애플리케이션 빌드 담당 (UID 1000 기본값 유지)
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # 3. Kubectl 컨테이너: Kubernetes 배포 관리 담당
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # 4. JNLP 컨테이너: Jenkins 에이전트의 기본 연결 및 제어 담당
    - name: jnlp
      image: jenkins/inbound-agent:latest
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "256Mi"
          cpu: "100m"
          ephemeral-storage: "1Gi"

  volumes:
    - name: docker-config
      secret:
        secretName: "dockertoken"
        items:
          - key: ".dockerconfigjson"
            path: config.json
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY = "docker.io/leeplayed"
        IMAGE = "petclinic"
        TAG = "${env.BUILD_NUMBER}"
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
                container('maven') {
                    // Maven 빌드 문제를 해결하기 위한 최종 안정화 버전
                    sh """
export HOME=\$WORKSPACE
mkdir -p \$WORKSPACE/.m2
mvn clean package -DskipTests -Dcheckstyle.skip=true -Dmaven.repo.local=\$WORKSPACE/.m2
"""
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                container('kaniko') {
                    // Kaniko 인증 및 권한 문제를 모두 해결한 최종 명령어
                    sh """
echo "===== Kaniko Build Start: ${REGISTRY}/${IMAGE}:${TAG} ====="

/kaniko/executor \\
  --context \$WORKSPACE \\
  --dockerfile Dockerfile \\
  --destination ${REGISTRY}/${IMAGE}:${TAG} \\
  --snapshot-mode=redo \\
  --cache=true
"""
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
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
