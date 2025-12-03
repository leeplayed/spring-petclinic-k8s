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
                echo \"------------------------------------------------------------\"
                echo \"❗ BUILD STOPPED ON PURPOSE\"
                echo \"❗ Send me the output of the Check Workspace stage.\"
                echo \"❗ Then I will generate the FINAL Jenkinsfile for you.\"
                echo \"------------------------------------------------------------\"
                error("Stopping pipeline here for workspace path verification")
            }
        }
    }

    post {
        always {
            echo ">>> Pipeline Finished."
        }
    }
}
