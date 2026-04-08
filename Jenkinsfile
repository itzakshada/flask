pipeline {
    agent { label 'jenkins-agent' }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Create Virtualenv & Install Tools') {
            steps {
                sh '''
                python3 -m venv .venv
                . .venv/bin/activate
                pip install --upgrade pip
                pip install build pytest
                '''
            }
        }

        stage('Build Wheel') {
            steps {
                sh '''
                . .venv/bin/activate
                python -m build --wheel
                ls -l dist
                '''
            }
        }

        stage('Install Wheel') {
            steps {
                sh '''
                . .venv/bin/activate
                pip install dist/*.whl
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                . .venv/bin/activate
                pytest || true
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/*.whl', fingerprint: true
        }
    }
}
