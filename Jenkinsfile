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

    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      tty: true
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      securityContext:
        runAsUser: 0
      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
          ephemeral-storage: 2Gi
        limits:
          cpu: "1"
          memory: "2Gi"
          ephemeral-storage: 5Gi
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: config.json
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/
        - name: maven-cache
          mountPath: /root/.m2

    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      tty: true
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
          ephemeral-storage: 2Gi
        limits:
          cpu: "1"
          memory: "2Gi"
          ephemeral-storage: 5Gi
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/
        - name: maven-cache
          mountPath: /root/.m2

    - name: kubectl
      image: leeplayed/kubectl:1.28
      tty: true
      command: ["/bin/sh"]
      args: ["-c", "sleep infinity"]
      resources:
        requests:
          cpu: "250m"
          memory: "512Mi"
          ephemeral-storage: 1Gi
        limits:
          cpu: "500m"
          memory: "1Gi"
          ephemeral-storage: 2Gi
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

    - name: jnlp
      image: jenkins/inbound-agent:latest
      resources:
        requests:
          cpu: "100m"
          memory: "256Mi"
          ephemeral-storage: 500Mi
        limits:
          cpu: "500m"
          memory: "512Mi"
          ephemeral-storage: 1Gi
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

  volumes:
    - name: docker-config
      secret:
        secretName: dockertoken
        items:
        - key: ".dockerconfigjson"
          path: config.json

    - name: workspace-volume
      emptyDir: {}

    - name: maven-cache
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
mvn clean package \\
    -DskipTests \\
    -Dcheckstyle.skip=true \\
    -Dmaven.repo.local=/root/.m2
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
kubectl set image deployment/petclinic petclinic-container=${REGISTRY}/${IMAGE}:${TAG} -n ${K8S_NAMESPACE}
kubectl rollout status deployment/petclinic -n ${K8S_NAMESPACE} --timeout=5m
"""
                }
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS: Build & Deploy Completed!"
        }
        failure {
            echo "🔥 FAILED: Check the Jenkins logs!"
        }
    }
}
