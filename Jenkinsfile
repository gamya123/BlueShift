pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t blueshift:latest .'
            }
        }

        stage('Deploy New Container') {
            steps {
                sh '''
                    docker stop blueshift-new || true
                    docker rm blueshift-new || true

                    docker run -d \
                        --name blueshift-new \
                        -p 8082:80 \
                        blueshift:latest
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for application to start..."
                    sleep 5

                    if curl -f http://localhost:8082; then
                        echo "✅ Health check passed!"
                    else
                        echo "❌ Health check failed!"
                        docker logs blueshift-new
                        docker stop blueshift-new || true
                        docker rm blueshift-new || true
                        exit 1
                    fi
                '''
            }
        }
    }
}
