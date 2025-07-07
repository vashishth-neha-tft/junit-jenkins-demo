pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
        ARTIFACTORY_SERVER_ID = "my-artifactory"
    }

    stages {
        stage('Select Test Framework') {
            steps {
                script {
                    env.TEST_TOOLS = input(
                        id: 'testFramework',
                        message: 'Select test framework',
                        parameters: [
                            choice(name: 'TEST_FRAMEWORK', 
                                  choices: ['none', 'junit', 'keploy'], 
                                  description: 'Choose either JUnit or Keploy')
                        ]
                    )
                }
            }
        }

        stage('Select Security Scanner') {
            steps {
                script {
                    env.SECURITY_TOOL = input(
                        id: 'securityTool',
                        message: 'Select security scanner',
                        parameters: [
                            choice(name: 'SECURITY_SCANNER', 
                                  choices: ['none', 'gitleaks', 'snyk'], 
                                  description: 'Choose secret scanning tool')
                        ]
                    )
                }
            }
        }

        stage('Select Analysis Platform') {
            steps {
                script {
                    env.ANALYSIS_TOOL = input(
                        id: 'analysisTool',
                        message: 'Select analysis platform',
                        parameters: [
                            choice(name: 'ANALYSIS_PLATFORM', 
                                  choices: ['none', 'sonarqube', 'jfrog'], 
                                  description: 'Choose code analysis platform')
                        ]
                    )
                }
            }
        }

        /* Test Framework Stages */
        stage('JUnit Tests') {
            when {
                expression { env.TEST_TOOLS == 'junit' }
            }
            steps {
                echo 'Running Maven build and JUnit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('Keploy Tests') {
            when {
                expression { env.TEST_TOOLS == 'keploy' }
            }
            steps {
                echo 'Installing and running Keploy...'
                sh '''
                    curl -sSL https://keploy.io/install.sh | bash
                    sudo mv keploy /usr/local/bin/
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 10
                '''
            }
        }

        /* Security Scanning Stages */
        stage('GitLeaks Scan') {
            when {
                expression { env.SECURITY_TOOL == 'gitleaks' }
            }
            steps {
                echo 'Running GitLeaks secret scanning...'
                sh '''
                    curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh
                    ./bin/gitleaks detect --source=. --report-format=json --report-path=gitleaks-report.json
                '''
                archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
            }
        }

        stage('Snyk Scan') {
            when {
                expression { env.SECURITY_TOOL == 'snyk' }
            }
            steps {
                echo 'Running Snyk vulnerability scan...'
                sh '''
                    npm install -g snyk
                    snyk auth ${SNYK_TOKEN}
                    snyk test --all-projects --json-file-output=snyk-report.json
                '''
                archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
            }
        }

        /* Analysis Platform Stages */
        stage('SonarQube Analysis') {
            when {
                expression { env.ANALYSIS_TOOL == 'sonarqube' }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${JOB_NAME} \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.sources=src/main/java
                    '''
                }
            }
        }

        stage('JFrog Artifactory Upload') {
            when {
                expression { env.ANALYSIS_TOOL == 'jfrog' }
            }
            steps {
                echo 'Uploading artifacts to JFrog...'
                script {
                    def server = Artifactory.server(env.ARTIFACTORY_SERVER_ID)
                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "libs-release-local/${JOB_NAME}/${BUILD_NUMBER}/"
                        }]
                    }"""
                    server.upload(uploadSpec)
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            script {
                if (env.SECURITY_TOOL != 'none') {
                    echo "Security scan (${env.SECURITY_TOOL}) completed"
                }
            }
        }
        success {
            echo """Build succeeded with:
                   Test Framework: ${env.TEST_TOOLS}
                   Security Scanner: ${env.SECURITY_TOOL}
                   Analysis Platform: ${env.ANALYSIS_TOOL}"""
        }
        failure {
            echo 'Pipeline failed. Check console output for details.'
            emailext body: 'Check failed build at ${BUILD_URL}',
                      subject: 'Pipeline Failed: ${JOB_NAME}',
                      to: 'team@example.com'
        }
    }
}