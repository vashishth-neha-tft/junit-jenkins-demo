pipeline {
    agent any
    environment {
        SONAR_SERVER = "MySonarQube"  // Must match Jenkins config
    }
    stages {
        stage('Build & Test') {
            steps {
                sh 'mvn clean package'  // This will:
                                        // 1. Compile code
                                        // 2. Run tests (surefire)
                                        // 3. Generate JaCoCo coverage
                junit 'target/surefire-reports/*.xml'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                echo '🔍 Starting SonarQube Analysis...'
                withSonarQubeEnv(SONAR_SERVER) {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.projectName="JUnit Jenkins Demo" \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.test.inclusions=**/*Test.java
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