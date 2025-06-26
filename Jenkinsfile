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
        
        // Debug stage to verify variables
        stage('Pre-Sonar Check') {
            steps {
                script {
                    echo "SonarQube Server: ${SONAR_SERVER}"
                    echo "Host URL: ${env.SONAR_HOST_URL}"
                }
            }
        }
        
        stage('SonarQube Analysis') {
            agent any  // Explicit agent
            steps {
                echo 'Starting SonarQube Analysis...'
                withSonarQubeEnv(SONAR_SERVER) {
                    sh '''
                        echo "Visible ENV VARS:"
                        env | sort
                        
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