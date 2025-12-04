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
  serviceAccountName: jenkins 
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
    - key: "node.kubernetes.io/disk-pressure"
      operator: "Exists"
      effect: "NoSchedule"

  containers:
    # ---------------------------------------------------------
    # 1) Kaniko 컨테이너
    # ---------------------------------------------------------
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      tty: true
      securityContext:
        runAsUser: 0
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: .dockerconfigjson
          readOnly: true
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"

    # ---------------------------------------------------------
    # 2) Maven 컨테이너
    # ---------------------------------------------------------
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "512Mi"
          cpu: "500m"

    # ---------------------------------------------------------
    # 3) Kubectl 컨테이너 (🔥 해결방법 1 적용됨)
    # ---------------------------------------------------------
    - name: kubectl
      image: registry.k8s.io/kubectl:v1.28.0
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"
      resources:
        requests:
          memory: "128Mi"
          cpu: "100m"

    # ---------------------------------------------------------
    # 4) JNLP 에이전트
    # ---------------------------------------------------------
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
