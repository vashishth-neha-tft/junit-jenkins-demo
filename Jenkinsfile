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
            post {
                success {
                    script {
                        // Get test result summary
                        def testResult = junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
                        def totalTests = testResult.totalCount
                        def passedTests = testResult.passCount
                        
                        // Calculate pass percentage
                        def passPercentage = (passedTests / totalTests) * 100
                        
                        // Set environment variable if pass rate > 50%
                        if (passPercentage > 50) {
                            env.RUN_SONARQUBE = 'true'
                            echo "Test pass rate ${passPercentage}% > 50%, SonarQube will run"
                        } else {
                            env.RUN_SONARQUBE = 'false'
                            echo "Test pass rate ${passPercentage}% <= 50%, SonarQube will NOT run"
                        }
                    }
                }
            }
        }

        stage('Verify target/classes') {
            steps {
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('SonarQube Analysis') {
            when {
                environment name: 'RUN_SONARQUBE', value: 'true'
            }
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
            when {
                environment name: 'RUN_SONARQUBE', value: 'true'
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}