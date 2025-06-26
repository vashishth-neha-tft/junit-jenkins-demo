pipeline {
    agent any
    environment {
        SONAR_SERVER = "MySonarQube"  // Must match Jenkins config
    }
    stages {
        stage('Build & Test') {
            steps {
                sh 'mvn clean package'  // Compiles + runs tests
                junit 'target/surefire-reports/*.xml'  // Archives test results
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(SONAR_SERVER) {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=myapp \
                        -Dsonar.projectName="My App" \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true  // Fails if quality declines
                }
            }
        }
    }
}