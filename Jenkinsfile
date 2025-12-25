pipeline {
  agent any
  options {
    timestamps()
    skipDefaultCheckout(true)
  }

  stages {
    stage('Checkout (clean)') {
      steps {
        deleteDir()
        checkout scm
      }
    }

    stage('Test (Go in Docker)') {
      steps {
        script {
          docker.image('golang:1.22').inside('--user 0:0') {
            sh 'go version'
            sh 'go test ./...'
          }
        }
      }
    }

    stage('Build (Go in Docker)') {
      steps {
        script {
          docker.image('golang:1.22').inside('--user 0:0') {
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
