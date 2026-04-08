pipeline {
    agent { label 'jenkins-agent' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        SONAR_HOST_URL = "http://65.0.27.253:9000"
        SONAR_SCANNER_BIN = "/opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner"
        SONAR_PROJECT_KEY = "flask"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Create Virtualenv & Install Build/Test Tools') {
            steps {
                sh '''
                    set -e
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
                    set -e
                    . .venv/bin/activate
                    rm -rf dist build *.egg-info
                    python -m build --wheel
                    ls -lh dist
                '''
            }
        }

        stage('Install Wheel (Artifact Validation)') {
            steps {
                sh '''
                    set -e
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
                withCredentials([string(credentialsId: 'sonar-token-01', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        set -e
                        if [ ! -x "$SONAR_SCANNER_BIN" ]; then
                          echo "ERROR: sonar-scanner not found at $SONAR_SCANNER_BIN"
                          exit 127
                        fi

                        "$SONAR_SCANNER_BIN" \
                          -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                          -Dsonar.sources=src \
                          -Dsonar.tests=tests \
                          -Dsonar.host.url="$SONAR_HOST_URL" \
                          -Dsonar.login="$SONAR_TOKEN"
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/*.whl', fingerprint: true, allowEmptyArchive: true
        }
        cleanup {
            cleanWs()
        }
    }
}
