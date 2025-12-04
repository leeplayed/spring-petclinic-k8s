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
    # =======================
    # ① Kaniko
    # =======================
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
          subPath: config.json
          readOnly: true
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

    # =======================
    # ② Maven
    # =======================
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # =======================
    # ③ Kubectl (직접 제작 이미지)
    # =======================
    - name: kubectl
      image: leeplayed/kubectl:1.28
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # =======================
    # ④ JNLP
    # =======================
    - name: jnlp
      image: jenkins/inbound-agent:latest
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

  volumes:
    - name: docker-config
      secret:
        secretName: dockertoken
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

mvn clean package \
  -DskipTests \
  -Dcheckstyle.skip=true \
  -Dmaven.repo.local=\$WORKSPACE/.m2
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
            echo "🎉 SUCCESS: Build & Deploy Completed!"
            echo "➡️ Image: ${REGISTRY}/${IMAGE}:${TAG}"
        }
        failure {
            echo "🔥 FAILED: Check the Jenkins logs!"
        }
    }
}
