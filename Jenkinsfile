pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
        ARTIFACTORY_SERVER_ID = "my-artifactory"
    }

    stages {
        stage('Tool Selection') {
            steps {
                script {
                    // Test framework selection
                    env.TEST_TOOLS = input(
                        id: 'testFramework',
                        message: 'Select test framework',
                        parameters: [
                            choice(name: 'TEST_FRAMEWORK', 
                                  choices: ['none', 'junit', 'keploy'], 
                                  description: 'Choose testing framework')
                        ]
                    )

                    // Security scanner selection
                    env.SECURITY_TOOL = input(
                        id: 'securityTool',
                        message: 'Select security scanner',
                        parameters: [
                            choice(name: 'SECURITY_SCANNER', 
                                  choices: ['none', 'gitleaks', 'snyk'], 
                                  description: 'Choose security scanning tool')
                        ]
                    )

                    // Analysis platform selection
                    env.ANALYSIS_TOOL = input(
                        id: 'analysisTool',
                        message: 'Select analysis platform',
                        parameters: [
                            choice(name: 'ANALYSIS_PLATFORM', 
                                  choices: ['none', 'sonarqube', 'jfrog'], 
                                  description: 'Choose analysis platform')
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
                archiveArtifacts artifacts: 'target/surefire-reports/*.xml', allowEmptyArchive: true
            }
        }

        stage('Keploy Setup') {
            when {
                expression { env.TEST_TOOLS == 'keploy' }
            }
            steps {
                echo 'Installing Keploy...'
                script {
                    try {
                        // Create bin directory if it doesn't exist
                        sh 'mkdir -p $HOME/bin'
                        
                        // Download and install Keploy
                        sh '''
                            curl -sSL https://keploy.io/install.sh | bash -s -- -b $HOME/bin
                            export PATH="$HOME/bin:$PATH"
                            keploy version
                        '''
                        
                        // Verify installation
                        def keployVersion = sh(script: '$HOME/bin/keploy version', returnStdout: true).trim()
                        echo "Keploy installed successfully: ${keployVersion}"
                    } catch (Exception e) {
                        error "Failed to install Keploy: ${e.message}"
                    }
                }
            }
        }

        stage('Keploy Tests') {
            when {
                expression { env.TEST_TOOLS == 'keploy' }
            }
            steps {
                echo 'Running Keploy tests...'
                script {
                    try {
                        withEnv(["PATH=$HOME/bin:$PATH"]) {
                            sh '''
                                keploy test -c "mvn spring-boot:run" \
                                --delay 10 \
                                --config-path ./keploy-config.yaml \
                                --testsets-path ./keploy-testsets
                            '''
                        }
                        archiveArtifacts artifacts: 'keploy-testsets/**/*', allowEmptyArchive: true
                    } catch (Exception e) {
                        error "Keploy tests failed: ${e.message}"
                    }
                }
            }
        }

        /* Security Scanning Stages */
        stage('GitLeaks Scan') {
            when {
                expression { env.SECURITY_TOOL == 'gitleaks' }
            }
            steps {
                echo 'Running GitLeaks secret scanning...'
                script {
                    try {
                        sh '''
                            # Install GitLeaks if not present
                            if ! command -v gitleaks >/dev/null 2>&1; then
                                curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh
                                sudo mv bin/gitleaks /usr/local/bin/
                                rm -rf bin
                            fi
                            
                            # Run scan
                            gitleaks detect --source=. \
                                --report-format=json \
                                --report-path=gitleaks-report.json \
                                --verbose
                        '''
                        archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                    } catch (Exception e) {
                        unstable "GitLeaks scan found potential secrets or failed: ${e.message}"
                    }
                }
            }
        }

        stage('Snyk Scan') {
            when {
                expression { env.SECURITY_TOOL == 'snyk' && env.SNYK_TOKEN }
            }
            steps {
                echo 'Running Snyk vulnerability scan...'
                script {
                    try {
                        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                            sh '''
                                npm install -g snyk
                                snyk auth ${SNYK_TOKEN}
                                snyk test --all-projects --json-file-output=snyk-report.json
                            '''
                        }
                        archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                    } catch (Exception e) {
                        unstable "Snyk scan found vulnerabilities or failed: ${e.message}"
                    }
                }
            }
        }

        /* Analysis Platform Stages */
        stage('SonarQube Analysis') {
            when {
                expression { env.ANALYSIS_TOOL == 'sonarqube' }
            }
            steps {
                echo 'Running SonarQube analysis...'
                script {
                    try {
                        withSonarQubeEnv("${SONAR_SERVER}") {
                            sh '''
                                mvn sonar:sonar \
                                -Dsonar.projectKey=${JOB_NAME} \
                                -Dsonar.java.binaries=target/classes \
                                -Dsonar.sources=src/main/java \
                                -Dsonar.tests=src/test/java \
                                -Dsonar.junit.reportPaths=target/surefire-reports
                            '''
                        }
                    } catch (Exception e) {
                        error "SonarQube analysis failed: ${e.message}"
                    }
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
                    try {
                        def server = Artifactory.server(env.ARTIFACTORY_SERVER_ID)
                        def uploadSpec = """{
                            "files": [{
                                "pattern": "target/*.jar",
                                "target": "libs-release-local/${JOB_NAME}/${BUILD_NUMBER}/",
                                "props": "build.name=${JOB_NAME};build.number=${BUILD_NUMBER}"
                            }]
                        }"""
                        def buildInfo = server.upload(uploadSpec)
                        server.publishBuildInfo(buildInfo)
                    } catch (Exception e) {
                        error "Artifactory upload failed: ${e.message}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            script {
                // Archive any remaining artifacts
                archiveArtifacts artifacts: '**/target/*.jar,**/target/*.war', allowEmptyArchive: true
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
            emailext body: """Pipeline ${currentBuild.currentResult}: ${JOB_NAME} #${BUILD_NUMBER}
                              Check details at: ${BUILD_URL}""",
                      subject: "Pipeline ${currentBuild.currentResult}: ${JOB_NAME}",
                      to: 'team@example.com'
        }
    }
}