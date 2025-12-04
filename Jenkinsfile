pipeline {
    agent {
        kubernetes {
            label 'kaniko-build'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:

    # --------------------------
    # 1) Kaniko 컨테이너
    # --------------------------
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: config.json
        - name: workspace-volume
          mountPath: /home/jenkins/agent/workspace/

    # --------------------------
    # 2) Maven 컨테이너
    # --------------------------
    - name: maven
      image: maven:3.9.6-eclipse-temurin-17
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # --------------------------
    # 3) Kubectl 컨테이너
    # --------------------------
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

    # --------------------------
    # 4) JNLP 컨테이너 (기본)
    # --------------------------
    - name: jnlp
      image: jenkins/inbound-agent:latest
      volumeMounts:
        - name: workspace-volume
          mountPath: "/home/jenkins/agent/workspace/"

  volumes:
    # 🔥 1) DockerHub 로그인 Secret (필수)
    - name: docker-config
      secret:
        secretName: "dockertoken"
        items:
        - key: .dockerconfigjson
          path: config.json

    # 🔥 2) Jenkins workspace 공유용 볼륨 (필수)
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
mvn clean package -DskipTests -Dcheckstyle.skip=true -Dmaven.repo.local=\$WORKSPACE/.m2
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
