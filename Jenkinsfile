pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                echo ">>> 1. Checking out code from SCM..."
                checkout scm
            }
        }

        stage('Check Workspace') {
            steps {
                echo ">>> 2. Checking Workspace Structure..."
                sh "pwd"
                sh "ls -al"
                sh "find . -maxdepth 4 -type f -name pom.xml"
            }
        }

        stage('STOP for Debug') {
            steps {
                echo "------------------------------------------------------------"
                echo "⚠️  STOPPED: Need workspace info to continue."
                echo "⚠️  Send me the output of Check Workspace stage."
                echo "------------------------------------------------------------"
                error("Stopping pipeline for workspace verification")
            }
        }
    }

    post {
        always {
            echo ">>> Pipeline Finished."
        }
    }
}
