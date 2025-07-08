pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {

        // === Step 1: Select TESTING tools ===
        stage('Select Testing Tools') {
            steps {
                script {
                    def testChoice = input(
                        id: 'testChoice',
                        message: 'Select testing tools to run',
                        parameters: [
                            choice(name: 'TEST_TOOLS', choices: ['none', 'junit', 'keploy', 'both'], description: 'Choose test tools (junit, keploy, or both)')
                        ]
                    )
                    env.TEST_TOOLS = testChoice
                }
            }
        }

        // === Step 2: Select SECURITY ANALYSIS tools ===
        stage('Select Security Tools') {
            steps {
                script {
                    def securityChoice = input(
                        id: 'securityChoice',
                        message: 'Select security analysis tools to run',
                        parameters: [
                            choice(name: 'SECURITY_TOOLS', choices: ['none', 'gitleaks', 'snyk', 'both'], description: 'Choose secret scanning tools (gitleaks, snyk, or both)')
                        ]
                    )
                    env.SECURITY_TOOLS = securityChoice
                }
            }
        }

        // === Step 3: Select QUALITY / ARTIFACT tools ===
        stage('Select Code Quality / Artifact Tools') {
            steps {
                script {
                    def qaChoice = input(
                        id: 'qaChoice',
                        message: 'Select code quality and artifact upload tools',
                        parameters: [
                            choice(name: 'QA_TOOLS', choices: ['none', 'sonarqube', 'jfrog', 'both'], description: 'Choose SonarQube, JFrog, or both')
                        ]
                    )
                    env.QA_TOOLS = qaChoice
                }
            }
        }

        // === Build and Test ===
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

        // === Keploy Setup & Run ===
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

        // === Security Scans ===
        stage('Run Gitleaks Secret Scan') {
            when {
                expression { env.SECURITY_TOOLS == 'gitleaks' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Gitleaks...'
                sh '''
                    docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect \
                        --source=/path \
                        --report-format=json \
                        --report-path=/path/gitleaks-report.json || echo "Gitleaks completed with findings"
                '''
                echo 'Gitleaks scan completed. Check gitleaks-report.json.'
            }
        }

        stage('Snyk Analysis') {
            when {
                expression { env.SECURITY_TOOLS == 'snyk' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Snyk analysis (placeholder)...'
                sh 'echo "Snyk analysis would run here..."'
            }
        }

        // === SonarQube Scan ===
        stage('SonarQube Scan') {
            when {
                expression { env.QA_TOOLS == 'sonarqube' || env.QA_TOOLS == 'both' }
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

        // === JFrog Upload ===
        stage('Upload to JFrog Artifactory') {
            when {
                expression { env.QA_TOOLS == 'jfrog' || env.QA_TOOLS == 'both' }
            }
            steps {
                echo 'Uploading artifact to JFrog Artifactory...'
                script {
                    def server = Artifactory.server 'my-artifactory'
                    def buildInfo = Artifactory.newBuildInfo()

                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "libs-release-local/"
                        }]
                    }"""

                    server.upload spec: uploadSpec, buildInfo: buildInfo
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo "✔ Build completed with test tools: ${env.TEST_TOOLS}, security tools: ${env.SECURITY_TOOLS}, QA tools: ${env.QA_TOOLS}"
        }
        failure {
            echo '✖ Pipeline failed. Check logs for details.'
        }
    }
}
