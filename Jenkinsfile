pipeline {
    agent { label 'jenkins-agent' }

    options {
        timestamps()
    }

    environment {
        VENV_DIR = ".venv"

        // SonarQube (Jenkins MASTER private IP)
        SONAR_HOST_URL = "http://10.0.1.116:9000"
        SONAR_SCANNER  = "/opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner"

        // Nexus
        NEXUS_IP = "13.233.100.158"
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Create Virtualenv & Install Tools') {
            steps {
                sh '''
                python3 -m venv ${VENV_DIR}
                . ${VENV_DIR}/bin/activate
                pip install --upgrade pip
                pip install build pytest twine
                '''
            }
        }

        stage('Build Wheel') {
            steps {
                sh '''
                . ${VENV_DIR}/bin/activate
                python -m build --wheel
                ls -l dist
                '''
            }
        }

        stage('Install Wheel') {
            steps {
                sh '''
                . ${VENV_DIR}/bin/activate
                pip install --force-reinstall dist/*.whl
                '''
            }
        }

        stage('Unit Tests (non-blocking)') {
            steps {
                sh '''
                . ${VENV_DIR}/bin/activate
                pytest || true
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([
                    string(credentialsId: 'sonar-token-02', variable: 'SONAR_TOKEN')
                ]) {
                    sh '''
                    ${SONAR_SCANNER} \
                      -Dsonar.projectKey=flask \
                      -Dsonar.sources=src \
                      -Dsonar.tests=tests \
                      -Dsonar.host.url=${SONAR_HOST_URL} \
                      -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Push Wheel to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus_pypi_creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh '''
                    . ${VENV_DIR}/bin/activate
                    twine upload \
                      --repository-url http://${NEXUS_IP}:8081/repository/python-repo/ \
                      -u ${NEXUS_USER} \
                      -p ${NEXUS_PASS} \
                      dist/*.whl
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                GIT_SHA=$(git rev-parse --short HEAD)
                IMAGE_TAG=${BUILD_NUMBER}-${GIT_SHA}

                docker build -t flask-ci:${IMAGE_TAG} .
                '''
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus_docker_creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh '''
                    GIT_SHA=$(git rev-parse --short HEAD)
                    IMAGE_TAG=${BUILD_NUMBER}-${GIT_SHA}

                    docker login ${NEXUS_IP}:8082 \
                      -u ${NEXUS_USER} \
                      -p ${NEXUS_PASS}

                    docker tag flask-ci:${IMAGE_TAG} \
                      ${NEXUS_IP}:8082/flask:${IMAGE_TAG}

                    docker push ${NEXUS_IP}:8082/flask:${IMAGE_TAG}
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
