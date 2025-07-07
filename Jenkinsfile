pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
        ARTIFACTORY_SERVER_ID = "my-artifactory"
    }

    stages {
        stage('Select Tools') {
            steps {
                script {
                    def testChoice = input(
                        id: 'testChoice',
                        message: 'Select testing tools to run',
                        parameters: [
                            choice(name: 'TEST_TOOLS', choices: ['none', 'junit', 'keploy', 'both'], description: 'Choose test tools')
                        ]
                    )
                    env.TEST_TOOLS = testChoice

                    def analysisChoice = input(
                        id: 'analysisChoice',
                        message: 'Select analysis tools to run',
                        parameters: [
                            choice(name: 'ANALYSIS_TOOLS', choices: ['none', 'sonarqube', 'jfrog', 'both'], description: 'Choose analysis tools')
                        ]
                    )
                    env.ANALYSIS_TOOLS = analysisChoice
                }
            }
        }

        stage('GitLeaks Scan') {
            steps {
                echo 'Running GitLeaks secret scanning...'
                sh '''
                    # Install GitLeaks if not present
                    if ! command -v gitleaks &> /dev/null; then
                        curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh
                        sudo mv bin/gitleaks /usr/local/bin/
                    fi
                    
                    # Run scan
                    gitleaks detect --source=. --report-path=gitleaks-report.json || true
                    
                    # Archive report
                    archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                '''
            }
        }

        stage('Build & Unit Test') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Checking compiled classes...'
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('Install Keploy') {
            when {
                expression { env.TEST_TOOLS == 'keploy' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Installing Keploy...'
                sh '''
                    curl --silent -O -L https://keploy.io/install.sh
                    chmod +x install.sh
                    bash install.sh
                    sudo mv keploy /usr/local/bin/keploy || true
                    sudo chmod +x /usr/local/bin/keploy
                '''
            }
        }

        stage('Run Keploy Tests') {
            when {
                expression { env.TEST_TOOLS == 'keploy' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Running Keploy to generate tests...'
                sh 'sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI'
            }
        }

        stage('SonarQube Scan') {
            when {
                expression { env.ANALYSIS_TOOLS == 'sonarqube' || env.ANALYSIS_TOOLS == 'both' }
            }
            steps {
                echo 'Running SonarQube scan...'
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                        -Dsonar.surefire.reportsPath=target/surefire-reports \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.java.test.binaries=target/test-classes
                    '''
                }
            }
        }

        stage('Upload to JFrog Artifactory') {
            when {
                expression { env.ANALYSIS_TOOLS == 'jfrog' || env.ANALYSIS_TOOLS == 'both' }
            }
            steps {
                echo 'Uploading artifact to JFrog Artifactory...'
                script {
                    def server = Artifactory.server(env.ARTIFACTORY_SERVER_ID)
                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "libs-release-local/test-upload/",
                            "props": "build.number=${BUILD_NUMBER}"
                        }]
                    }"""
                    
                    def buildInfo = server.upload(uploadSpec)
                    server.publishBuildInfo(buildInfo)
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
            script {
                // Check GitLeaks report if exists
                if (fileExists('gitleaks-report.json')) {
                    def leaks = readJSON file: 'gitleaks-report.json'
                    if (leaks.find { it }) {
                        unstable 'GitLeaks found potential secrets in the codebase'
                    }
                }
            }
        }
        success {
            echo "Build completed with selected test tools: ${env.TEST_TOOLS}, analysis tools: ${env.ANALYSIS_TOOLS}"
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}