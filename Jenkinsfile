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
    # 1) Kaniko 빌드 컨테이너
    # --------------------------
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      command: ["cat"]        # ❗ 컨테이너가 종료되지 않도록 반드시 유지
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
