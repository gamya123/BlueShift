pipeline {
    agent any

    environment {
        IMAGE = 'blueshift:latest'
        NGINX_CONFIG = '/etc/nginx/sites-available/blueshift'
        BLUE_PORT = '8081'
        GREEN_PORT = '8082'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${IMAGE} .
                '''
            }
        }

        stage('Detect Active Color') {
            steps {
                script {
                    def activePort = sh(
                        script: "grep -oP 'proxy_pass http://127\\.0\\.0\\.1:\\K[0-9]+' ${NGINX_CONFIG}",
                        returnStdout: true
                    ).trim()

                    if (activePort == env.BLUE_PORT) {
                        env.ACTIVE_COLOR = 'BLUE'
                        env.ACTIVE_PORT = env.BLUE_PORT
                        env.TARGET_COLOR = 'GREEN'
                        env.TARGET_PORT = env.GREEN_PORT
                        env.TARGET_CONTAINER = 'blueshift-green'
                    } else if (activePort == env.GREEN_PORT) {
                        env.ACTIVE_COLOR = 'GREEN'
                        env.ACTIVE_PORT = env.GREEN_PORT
                        env.TARGET_COLOR = 'BLUE'
                        env.TARGET_PORT = env.BLUE_PORT
                        env.TARGET_CONTAINER = 'blueshift-blue'
                    } else {
                        error("Unknown active port: ${activePort}")
                    }

                    echo "Active color: ${env.ACTIVE_COLOR}"
                    echo "Active port: ${env.ACTIVE_PORT}"
                    echo "Target color: ${env.TARGET_COLOR}"
                    echo "Target port: ${env.TARGET_PORT}"
                    echo "Target container: ${env.TARGET_CONTAINER}"
                }
            }
        }

        stage('Deploy Inactive Container') {
            steps {
                sh '''
                    echo "Deploying ${TARGET_COLOR} container..."

                    docker stop ${TARGET_CONTAINER} || true
                    docker rm ${TARGET_CONTAINER} || true

                    docker run -d \
                        --name ${TARGET_CONTAINER} \
                        -p ${TARGET_PORT}:80 \
                        ${IMAGE}

                    echo "${TARGET_CONTAINER} started successfully."
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for ${TARGET_COLOR} application..."
                    sleep 5

                    if curl -f http://127.0.0.1:${TARGET_PORT}; then
                        echo "Health check passed for ${TARGET_COLOR}!"
                    else
                        echo "Health check failed for ${TARGET_COLOR}!"

                        docker logs ${TARGET_CONTAINER} || true
                        docker stop ${TARGET_CONTAINER} || true
                        docker rm ${TARGET_CONTAINER} || true

                        exit 1
                    fi
                '''
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                    echo "Switching traffic to ${TARGET_COLOR}..."

                    sudo -n /usr/local/bin/blueshift-switch ${TARGET_PORT}

                    echo "Traffic switched to ${TARGET_COLOR}!"
                '''
            }
        }

        stage('Verify Traffic') {
            steps {
                sh '''
                    echo "Verifying active deployment..."

                    sleep 2

                    curl -f http://127.0.0.1:8090

                    echo ""
                    echo "BlueShift deployment successful!"
                    echo "Active color: ${TARGET_COLOR}"
                    echo "Active port: ${TARGET_PORT}"
                '''
            }
        }
    }

    post {
        success {
            echo 'Blue-Green deployment completed successfully!'
        }

        failure {
            echo 'Blue-Green deployment failed. Existing active version remains available.'
        }
    }
}
