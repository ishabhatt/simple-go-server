pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Test (in Go Docker image)') {
      steps {
        script {
          docker.image('golang:1.22').inside('-u 1000:1000') {
            sh 'go test ./...'
          }
        }
      }
    }

    stage('Build (in Go Docker image)') {
      steps {
        script {
          docker.image('golang:1.22').inside('-u 1000:1000') {
            sh 'mkdir -p dist'
            sh 'go build -o dist/simple-go-server .'
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dist/**', fingerprint: true
    }
  }
}

