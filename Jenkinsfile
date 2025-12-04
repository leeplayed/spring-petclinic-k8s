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
  # Jenkins Pod 템플릿의 보안 컨텍스트 설정
  securityContext:
    runAsUser: 1000
    fsGroup: 1000
  # 컨트롤 플레인 노드 등 특정 노드에서 실행되도록 허용
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
    - key: "node.kubernetes.io/disk-pressure"
      operator: "Exists"
      effect: "NoSchedule"
  containers:
    # 1. Kaniko 컨테이너: 도커 이미지 빌드 및 레지스트리 푸시 담당 (도커 데몬 불필요)
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["cat"]
      tty: true
      volumeMounts:
        # 도커 레지스트리 인증 정보 (dockertoken Secret) 마운트
        - name: docker-config
          mountPath: /kaniko/.docker/
          readOnly: true
        # 워크스페이스 공유 볼륨
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"

    # 2. Maven 컨테이너: Java/Spring Boot 애플리케이션 빌드 담당
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["cat"]
      tty: true
      volumeMounts:
        # 워크스페이스 공유 볼륨 (빌드된 jar 파일 접근)
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "512Mi"
          cpu: "500m"

    # 3. Kubectl 컨테이너: Kubernetes 배포 관리 담당
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        # 워크스페이스 공유 볼륨
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "128Mi"
          cpu: "100m"

    # 4. JNLP 컨테이너: Jenkins 에이전트의 기본 연결 및 제어 담당
    - name: jnlp
      image: jenkins/inbound-agent:latest
      volumeMounts:
        # 워크스페이스 공유 볼륨
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "256Mi"
          cpu: "100m"
          ephemeral-storage: "1Gi"

  volumes:
    # 도커 레지스트리 인증 정보 (Secret으로 정의되어 있어야 함)
    - name: docker-config
      secret:
        secretName: dockertoken
    # 컨테이너 간 파일 공유를 위한 임시 디렉토리 볼륨
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        // 도커 레지스트리 주소
        REGISTRY = "docker.io/leeplayed"
        // 이미지 이름
        IMAGE = "petclinic"
        // 태그는 젠킨스 빌드 번호를 사용
        TAG = "${env.BUILD_NUMBER}"
        // 배포할 쿠버네티스 네임스페이스
        K8S_NAMESPACE = "app"
    }

    stages {
        stage('Checkout') {
            steps {
                // 'github-ssh-key' Credential ID를 사용하여 소스 코드 체크아웃
                git branch: 'main',
                    url: 'git@github.com:leeplayed/spring-petclinic-k8s.git',
                    credentialsId: 'github-ssh-key'
            }
        }

        stage('Maven Build') {
            steps {
                // maven 컨테이너에서 빌드 실행
                container('maven') {
                    // Maven 로컬 리포지토리 경로를 MAVEN_OPTS 환경 변수를 통해 설정합니다.
                    sh '''
# 로컬 Maven 캐시 디렉토리를 워크스페이스 내부에 생성합니다.
mkdir -p $WORKSPACE/.m2

# MAVEN_OPTS를 사용하여 로컬 리포지토리 경로를 환경 변수로 설정하고 Maven을 실행합니다.
# 이렇게 하면 Maven 목표(goal)가 올바르게 인식됩니다.
export MAVEN_OPTS="-Dmaven.repo.local=$WORKSPACE/.m2"
./mvnw clean package -DskipTests -Dcheckstyle.skip=true
'''
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                // kaniko 컨테이너에서 이미지 빌드 및 푸시 실행
                container('kaniko') {
                    sh """
echo "===== Kaniko Build Start: ${REGISTRY}/${IMAGE}:${TAG} ====="
# Kaniko를 사용하여 Dockerfile과 빌드 아티팩트를 기반으로 이미지 빌드 및 푸시
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
                // kubectl 컨테이너에서 쿠버네티스 배포 업데이트 실행
                container('kubectl') {
                    sh """
echo "🔄 Updating Deployment Image..."
# 'petclinic' Deployment의 컨테이너 이미지를 새로 빌드된 태그로 업데이트
kubectl set image deployment/petclinic petclinic-container=${REGISTRY}/${IMAGE}:${TAG} -n ${K8S_NAMESPACE}

echo "⏳ Waiting for rollout..."
# 롤아웃이 완료될 때까지 대기
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
