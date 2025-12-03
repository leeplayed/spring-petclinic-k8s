pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: default
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args:
    - "--dockerfile=Dockerfile"
    - "--context=./"
    - "--destination=leeplayed/spring-petclinic:latest"
    - "--destination=leeplayed/spring-petclinic:${BUILD_NUMBER}"
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true

  # 🔥 JENKINS AGENT 필수 컨테이너
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ["$(JENKINS_SECRET)", "$(JENKINS_NAME)"]
    tty: true

  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-config
'''
        }
    }
