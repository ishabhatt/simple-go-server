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

    stage('Docker Build') {
      steps {
        sh 'docker build -t simple-go-server:${BUILD_NUMBER} .'
      }
    }


    stage('Smoke Test') {
       steps {
         sh '''
           set -eux
           cid=$(docker run -d -p 18081:8081 simple-go-server:${BUILD_NUMBER})
           sleep 2
           curl -fsS http://localhost:18081/posts || (docker logs "$cid"; exit 1)
           docker rm -f "$cid"
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dist/**', fingerprint: true
      sh 'docker image rm -f simple-go-server:${BUILD_NUMBER} || true'
    }
  }
}
