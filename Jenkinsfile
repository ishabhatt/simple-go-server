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
            sh '''
				set -euxo
				mkdir -p reports

				# Install gotestsum (outputs JUnit XML)
          		go install gotest.tools/gotestsum@v1.12.0
				export PATH="$(go env GOPATH)/bin:$PATH"

				# Run tests + write JUnit report
		        gotestsum \
		            --format standard-verbose \
		            --junitfile reports/junit.xml \
		            -- ./...
			'''
          }
        }
		// Publish in Jenkins "Test Result" trend UI
    	junit testResults: 'reports/junit.xml', keepLongStdio: true
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
        set -euxo pipefail

        # Run the built image (no -p needed)
        cid=$(docker run -d --name sgstest-${BUILD_NUMBER} simple-go-server:${BUILD_NUMBER})

        # Wait until /posts responds (max ~20s)
        for i in $(seq 1 20); do
          if docker run --rm --network container:$cid curlimages/curl:8.5.0 \
              -fsS http://localhost:8081/posts >/dev/null; then
            echo "Smoke test passed: /posts reachable"
            break
          fi
          sleep 1
          if [ "$i" -eq 20 ]; then
            echo "Smoke test failed. Logs:"
            docker logs "$cid" || true
            exit 1
          fi
        done

        docker rm -f "$cid"
      '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dist/**', fingerprint: true
      sh 'docker rm -f sgstest-${BUILD_NUMBER} || true'
      sh 'docker image rm -f simple-go-server:${BUILD_NUMBER} || true'
	  archiveArtifacts artifacts: 'reports/**', fingerprint: true
    }
  }
}
