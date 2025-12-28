pipeline {
  agent any
  options {
    timestamps()
    skipDefaultCheckout(true)
  }

  environment {
    IMAGE = "simple-go-server"
  }

  stages {
    stage('Checkout (clean)') {
      steps {
        deleteDir()
        checkout scm
      }
    }

	stage('Metadata') {
	  steps {
	    script {
	      env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
	      env.IMAGE_TAG = "${BUILD_NUMBER}-${env.GIT_SHA}"
	      env.IMAGE_REF = "${IMAGE}:${env.IMAGE_TAG}"
		  currentBuild.displayName = "#${BUILD_NUMBER} ${env.GIT_SHA}"
  		  currentBuild.description = "Image: ${env.IMAGE_REF}"
	    }
	    echo "IMAGE_REF=${env.IMAGE_REF}"
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
        sh 'docker build \
			--build-arg VCS_REF=${GIT_SHA} \
			--build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
			-t ${IMAGE_REF} .'
		sh 'docker inspect -f "{{ index .Config.Labels \\"org.opencontainers.image.revision\\" }}" ${IMAGE_REF}'
		sh 'docker inspect -f "{{ index .Config.Labels \\"org.opencontainers.image.created\\" }}" ${IMAGE_REF}'
      }
    }

	stage('Security Scan (Trivy)') {
	  steps {
	    sh '''
	      set -eux
	      mkdir -p reports

		  # Download Trivy HTML template into workspace (once per build)
	      docker run --rm \
	        --user 0:0 \
	        --volumes-from jenkins \
	        -w "$WORKSPACE" \
	        curlimages/curl:8.5.0 \
	        -fsSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl \
	        -o "$WORKSPACE/reports/html.tpl"

	      # Scan image; fail on CRITICAL
	      docker run --rm \
	        -v /var/run/docker.sock:/var/run/docker.sock \
			--volumes-from jenkins \
	        -w "$WORKSPACE" \
	        aquasec/trivy:0.51.1 image \
	        --severity CRITICAL \
	        --exit-code 1 \
	        --format template \
	        --template "@reports/html.tpl" \
	        --output $WORKSPACE/reports/trivy.html \
	        "$IMAGE"

		  ls -la reports | head
	    '''
	  }
	}

    stage('Smoke Test') {
      steps {
        sh '''
        set -euxo pipefail

        # Run the built image (no -p needed)
        cid=$(docker run -d --name sgstest-${BUILD_NUMBER} ${IMAGE_REF}

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
	  sh 'docker inspect -f "{{ index .Config.Labels \\"org.opencontainers.image.revision\\" }}" ${IMAGE_REF}'
      sh 'docker rm -f sgstest-${BUILD_NUMBER} || true'
      sh 'docker image rm -f ${IMAGE_REF} || true'
	  archiveArtifacts artifacts: 'reports/**', fingerprint: true
    }
  }
}
