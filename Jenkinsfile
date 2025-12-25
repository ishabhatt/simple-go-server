pipeline {
  agent any
  options {
    timestamps()
    skipDefaultCheckout(true)   // prevent the implicit auto-checkout :contentReference[oaicite:1]{index=1}
  }

  stages {
    stage('Checkout (clean)') {
      steps {
        deleteDir()
        checkout([$class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[url: 'https://github.com/ishabhatt/simple-go-server.git']]
        ])
        sh 'git status'
        sh 'git rev-parse --short HEAD'
      }
    }

    stage('Test (Go Docker image)') {
      steps {
        script {
          docker.image('golang:1.22').inside('--user 0:0') {
            	sh 'id'
		sh 'go test ./...'
          }
        }
      }
    }

    stage('Build (Go Docker image)') {
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

