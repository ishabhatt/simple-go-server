pipeline {
    // Defines where the pipeline will run. 'any' means any available agent.
    agent any 
    
    // The sequence of steps for the CI/CD process
    stages {
        // Stage 1: Checkout the source code
        stage('Checkout') {
            steps {
                // 'checkout scm' checks out the code from the source 
                // control management (SCM) linked to the Jenkins job configuration.
                checkout scm
            }
        }
        
        // Stage 2: Run tests using 'make test'
        stage('Test') {
            steps {
                // Executes the 'make test' command in the shell
                sh 'make test' 
            }
        }
        
        // Stage 3: Build the project using 'make build'
        stage('Build') {
            steps {
                // Executes the 'make build' command in the shell
                sh 'make build' 
            }
        }
    }
}
