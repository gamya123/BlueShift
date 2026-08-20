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
                    } else if (activePort == env.GREEN_PORT) {
                        env.ACTIVE_COLOR = 'GREEN'
                        env.ACTIVE_PORT = env.GREEN_PORT
                        env.TARGET_COLOR = 'BLUE'
                        env.TARGET_PORT = env.BLUE_PORT
                    } else {
                        error("Unknown active port: ${activePort}")
                    }

                    echo "Active color: ${env.ACTIVE_COLOR}"
                    echo "Target color: ${env.TARGET_COLOR}"
                    echo "Target port: ${env.TARGET_PORT}"
                }
            }
        }

        stage('Deploy Inactive Container') {
            steps {
                sh '''
                    CONTAINER="blueshift-${TARGET_COLOR,,}"

                    echo "Deploying ${TARGET_COLOR} container..."

                    docker stop "$CONTAINER" || true
                    docker rm "$CONTAINER" || true

                    docker run -d \
                        --name "$CONTAINER" \
                        -p ${TARGET_PORT}:80 \
                        ${IMAGE}
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
                        docker logs blueshift-${TARGET_COLOR,,} || true
                        docker stop blueshift-${TARGET_COLOR,,} || true
                        docker rm blueshift-${TARGET_COLOR,,} || true
                        exit 1
                    fi
                '''
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                    echo "Switching traffic to ${TARGET_COLOR}..."

                    sudo sed -i "s|proxy_pass http://127.0.0.1:[0-9]*;|proxy_pass http://127.0.0.1:${TARGET_PORT};|" ${NGINX_CONFIG}

                    sudo nginx -t

                    sudo systemctl reload nginx

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
                      
