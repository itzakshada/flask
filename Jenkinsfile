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

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=flask \
                      -Dsonar.sources=src \
                      -Dsonar.tests=tests \
                      -Dsonar.host.url=http://65.0.27.253:9000 \
                      -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/*.whl', fingerprint: true
        }
    }
}
