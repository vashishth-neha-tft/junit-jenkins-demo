pipeline {
    agent any
    
    tools {
        jdk 'jdk11'  // Make sure this matches your JDK tool name in Jenkins
        maven 'maven3' 
    }
    
    environment {
        SONAR_SERVER = "MySonarQube"
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
                junit 'target/surefire-reports/*.xml'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Verify classes exist before SonarQube
                    def classesExist = fileExists 'target/classes'
                    echo "Classes exist: ${classesExist}"
                    if (!classesExist) {
                        error "Compiled classes not found in target/classes!"
                    }
                    
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