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
    jenkins: kaniko
spec:
  nodeSelector:
    jenkins-node: "true"

  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/
      readOnly: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
        ephemeral-storage: "2Gi"

  - name: maven
    image: maven:3.9.6-eclipse-temurin-17
    command:
    - cat
    tty: true
    env:
    - name: JAVA_HOME
      value: /usr/local/openjdk-17
    resources:
      requests:
        memory: "1Gi"
        cpu: "1000m"
        ephemeral-storage: "1Gi"

  - name: kubectl
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
      secretName: dockertoken
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    tools {
        jdk null  // ❗ Jenkins Host JDK 사용 안 함 (Maven 컨테이너 JDK만 사용)
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
                container('maven') {
                    sh """
                    ./mvnw clean package -DskipTests -Dcheckstyle.skip=true
                    """
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                container('kaniko') {
                    sh """
                    echo "===== Kaniko Build Start ====="
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
                    kubectl apply -f k8s/deployment.yaml -n ${K8S_NAMESPACE}
                    kubectl apply -f k8s/service.yaml -n ${K8S_NAMESPACE}
                    kubectl rollout restart deployment petclinic -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment petclinic -n ${K8S_NAMESPACE} --timeout=5m
                    """
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy Success!"
        }
        failure {
            echo "🔥 Build Failed! Check logs!"
        }
    }
}
