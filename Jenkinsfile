pipeline {
    agent any
    
    environment {
        SONAR_SERVER = "MySonarQube"
        JFROG_SERVER = "MyJFrogServer"
    }
    
    stages {
        // Your existing stages (Build & Test, Verify, SonarQube Analysis, Quality Gate) here
        
        stage('Credentials Scanning') {
            parallel {
                stage('SonarQube Creds Scan') {
                    steps {
                        withSonarQubeEnv(SONAR_SERVER) {
                            sh 'mvn sonar:sonar -Dsonar.security.scan=true'
                        }
                    }
                }
                stage('Gitleaks Scan') {
                    steps {
                        sh '''
                            # Install and run gitleaks
                            curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.0.0/gitleaks_8.0.0_linux_x64.tar.gz | tar xz
                            ./gitleaks detect --source=. --report-format=json --report-path=gitleaks-report.json
                            
                            # Check for leaks
                            if [ -s gitleaks-report.json ]; then
                                echo "Credentials leaks detected!"
                                cat gitleaks-report.json
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Artifacts Scanning') {
            parallel {
                stage('SonarQube Artifact Scan') {
                    steps {
                        withSonarQubeEnv(SONAR_SERVER) {
                            sh 'mvn sonar:sonar -Dsonar.java.binaries=target/classes'
                        }
                    }
                }
                stage('JFrog Artifact Scan') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'jfrog-creds', usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')]) {
                            sh '''
                                # Upload and scan artifact with JFrog
                                curl -u $JFROG_USER:$JFROG_PASS -X PUT "https://${JFROG_SERVER}/artifactory/example-repo/my-app-${BUILD_NUMBER}.jar" -T target/*.jar
                                curl -u $JFROG_USER:$JFROG_PASS -X POST "https://${JFROG_SERVER}/api/scan/my-app-${BUILD_NUMBER}.jar"
                            '''
                        }
                    }
                }
            }
        }
    }
}