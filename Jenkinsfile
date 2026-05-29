pipeline {
    agent any

    environment {
        DOCKER_REPO  = "sebaabdou/api-aegis-ops"
        DOCKER_IMAGE = "${DOCKER_REPO}:${env.BUILD_ID}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Linting') {
            steps {
                sh '''
                    docker run --rm -i \
                      python:3.10-slim \
                      sh -c "pip install --quiet flake8 && \
                             cat > /tmp/app.py && \
                             flake8 /tmp/app.py --max-line-length=120" \
                      < app.py
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh """
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      aquasec/trivy:latest image \
                        --exit-code 1 \
                        --severity CRITICAL \
                        --ignore-unfixed \
                        --no-progress \
                        ${DOCKER_IMAGE}
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh """
                        echo \$DH_PASS | docker login -u \$DH_USER --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker logout
                    """
                }
            }
        }

        stage('Update GitOps Manifests') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh """
                        git config user.name  "Jenkins CI"
                        git config user.email "ci@aegis-ops.local"

                        sed -i "s|image: ${DOCKER_REPO}:.*|image: ${DOCKER_IMAGE}|g" \
                            k8s/deployment.yaml

                        git add k8s/deployment.yaml
                        git commit -m "ci: bump image to build-${env.BUILD_ID}" \
                          || echo "INFO : rien a committer"

                        git push \
                          "https://${GIT_USER}:${GIT_PASS}@github.com/SebaAbdou/api-aegis-ops.git" \
                          HEAD:main
                    """
                }
            }
        }
    }

    post {
        always { sh "docker rmi ${DOCKER_IMAGE} || true" }
        success { echo "CI reussie. ArgoCD prend le relais." }
        failure { echo "CI echouee. Consulter les logs." }
    }
}
