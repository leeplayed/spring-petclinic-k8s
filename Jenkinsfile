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
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
    - key: "node.kubernetes.io/disk-pressure"
      operator: "Exists"
      effect: "NoSchedule"

  containers:

    # --------------------------
    # 1) Kaniko (이미지 빌드 & Push)
    # --------------------------
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["cat"]         # 절대 변경 금지
      tty: true
      securityContext:
        runAsUser: 0           # 권한 문제 해결
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: .dockerconfigjson
          readOnly: true
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

    # --------------------------
    # 2) Maven
    # --------------------------
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # --------------------------
    # 3) Kubectl
    # --------------------------
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # --------------------------
    # 4) JNLP Agent
    # --------------------------
    - name: jnlp
      image: jenkins/inbound-agent:latest
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
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
                    sh """
export HOME=\$WORKSPACE
mkdir -p \$WORKSPACE/.m2
mvn clean package -DskipTests -Dmaven.repo.local=\$WORKSPACE/.m2
"""
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
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
            echo "🎉 SUCCESS! Build & Deploy Completed!"
            echo "➡️ Image: ${REGISTRY}/${IMAGE}:${TAG}"
        }
        failure {
            echo "🔥 FAILED! Check Jenkins Logs!"
        }
    }
}
