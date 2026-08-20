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

        stage('Deploy Container') {
            steps {
                sh '''
                    docker stop blueshift-container || true
                    docker rm blueshift-container || true
                    docker run -d --name blueshift-container -p 8080:80 blueshift:latest
                '''
            }
        }
    }
}
