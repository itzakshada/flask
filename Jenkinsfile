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
                pip install build pytest twine
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
                withCredentials([string(credentialsId: 'sonar-token-01', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                      -Dsonar.projectKey=flask \
                      -Dsonar.sources=src \
                      -Dsonar.tests=tests \
                      -Dsonar.host.url=http://65.0.27.253:9000 \
                      -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        /* =========================
           NEXUS PYPI PUSH (WHEEL)
           ========================= */
        stage('Push Wheel to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-pypi-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    . .venv/bin/activate
                    twine upload \
                      --repository-url http://13.233.100.158:8081/repository/python-repo/ \
                      -u $NEXUS_USER \
                      -p $NEXUS_PASS \
                      dist/*.whl
                    '''
                }
            }
        }

        /* =========================
           NEXUS DOCKER PUSH
           ========================= */
        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    GIT_SHA=$(git rev-parse --short HEAD)
                    IMAGE_TAG=${BUILD_NUMBER}-${GIT_SHA}

                    docker login 13.233.100.158:8082 -u $NEXUS_USER -p $NEXUS_PASS

                    docker tag flask-ci:${IMAGE_TAG} \
                      13.233.100.158:8082/flask:${IMAGE_TAG}

                    docker push 13.233.100.158:8082/flask:${IMAGE_TAG}
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

