pipeline {
    agent any

    // Add environment variables if needed
    environment {
        SONAR_SERVER = 'MySonarQube' // Must match your Jenkins SonarQube server config name
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Archive Results') {
            steps {
                junit 'target/surefire-reports/*.xml'
            }
        }
        
        // New SonarQube Analysis Stage
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    // For Maven projects, use the sonar:sonar goal
                    sh 'mvn sonar:sonar'
                    
                    // Alternative if you need specific parameters:
                    // sh 'mvn sonar:sonar -Dsonar.projectKey=my-project -Dsonar.projectName="My Project"'
                }
            }
        }
        
        // Optional Quality Gate Check
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}