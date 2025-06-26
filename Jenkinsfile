pipeline {
    agent any
    
    environment {
        SONAR_SERVER = "MySonarQube"
    }
    
    stages {
        stage('Build & Test') {
            steps {
                sh 'mvn clean package'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            steps {
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Starting SonarQube Analysis...'
                withSonarQubeEnv(SONAR_SERVER) {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.projectName="JUnit Jenkins Demo" \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
