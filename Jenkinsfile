pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
        // Removed direct credential reference from environment
    }

    stages {
        // === Initial Setup Stage ===
        stage('Setup Credentials') {
            steps {
                withCredentials([string(credentialsId: 'b413b14f-e1e4-48b7-8506-b35b0e939857', variable: 'SNYK_TOKEN')]) {
                    script {
                        env.SNYK_TOKEN = SNYK_TOKEN
                    }
                }
            }
        }

        // === Step 1: Select TESTING tools ===
        stage('Select Testing Tools') {
            steps {
                script {
                    env.TEST_TOOLS = input(
                        id: 'testChoice',
                        message: 'Select testing tools to run',
                        parameters: [
                            choice(name: 'TEST_TOOLS', choices: ['none', 'junit', 'keploy', 'both'], description: 'Choose test tools (junit, keploy, or both)')
                        ]
                    )
                }
            }
        }

        // === Step 2: Select SECURITY ANALYSIS tools ===
        stage('Select Security Tools') {
            steps {
                script {
                    env.SECURITY_TOOLS = input(
                        id: 'securityChoice',
                        message: 'Select security analysis tools to run',
                        parameters: [
                            choice(name: 'SECURITY_TOOLS', choices: ['none', 'gitleaks', 'snyk', 'both'], description: 'Choose secret scanning tools (gitleaks, snyk, or both)')
                        ]
                    )
                }
            }
        }

        // === Step 3: Select QUALITY / ARTIFACT tools ===
        stage('Select QA Tools') {
            steps {
                script {
                    env.QA_TOOLS = input(
                        id: 'qaChoice',
                        message: 'Select code quality and artifact upload tools',
                        parameters: [
                            choice(name: 'QA_TOOLS', choices: ['none', 'sonarqube', 'jfrog', 'both'], description: 'Choose SonarQube, JFrog, or both')
                        ]
                    )
                }
            }
        }

        // === Step 4: Build and JUnit Test ===
        stage('Build & JUnit Test') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify Compiled Classes') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Verifying compiled class files...'
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        // === Step 5: Keploy Installation and Test ===
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
                echo 'Running Keploy tests...'
                sh 'sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI'
            }
        }

        // === Step 6: Security Analysis ===
        stage('Gitleaks Scan') {
            when {
                expression { env.SECURITY_TOOLS == 'gitleaks' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Gitleaks secret scan...'
                sh '''
                    docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect \
                        --source=/path \
                        --report-format=json \
                        --report-path=/path/gitleaks-report.json || echo "Gitleaks completed with findings"
                '''
            }
        }

        stage('Snyk Analysis') {
            when {
                expression { env.SECURITY_TOOLS == 'snyk' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Snyk analysis...'
                withCredentials([string(credentialsId: 'b413b14f-e1e4-48b7-8506-b35b0e939857', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        if ! command -v snyk &> /dev/null; then
                            echo "Installing Snyk CLI..."
                            npm install -g snyk
                        fi

                        snyk auth $SNYK_TOKEN
                        snyk test
                    '''
                }
            }
        }

        // === Step 7: SonarQube Scan ===
        stage('SonarQube Scan') {
            when {
                expression { env.QA_TOOLS == 'sonarqube' || env.QA_TOOLS == 'both' }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.java.test.binaries=target/test-classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                        -Dsonar.surefire.reportsPath=target/surefire-reports
                    '''
                }
            }
        }

        // === Step 8: Upload to JFrog Artifactory ===
        stage('Upload to JFrog') {
            when {
                expression { env.QA_TOOLS == 'jfrog' || env.QA_TOOLS == 'both' }
            }
            steps {
                echo 'Uploading build artifacts to JFrog...'
                script {
                    def server = Artifactory.server('my-artifactory')
                    def buildInfo = Artifactory.newBuildInfo()

                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "libs-release-local/"
                        }]
                    }"""

                    server.upload spec: uploadSpec, buildInfo: buildInfo
                    server.publishBuildInfo(buildInfo)
                }
            }
        }

        // === Step 9: Docker Compliance Check ===
        stage('Docker Snyk Compliance Check') {
            steps {
                echo 'Running Snyk Docker compliance check...'
                withCredentials([string(credentialsId: 'b413b14f-e1e4-48b7-8506-b35b0e939857', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        if ! command -v snyk &> /dev/null; then
                            echo "Installing Snyk CLI..."
                            npm install -g snyk
                        fi

                        snyk auth $SNYK_TOKEN
                        docker build -t myapp:latest .
                        snyk test --docker myapp:latest --file=Dockerfile
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
        }
        success {
            echo "✔ Build succeeded using: Test Tools=${env.TEST_TOOLS}, Security Tools=${env.SECURITY_TOOLS}, QA Tools=${env.QA_TOOLS}"
        }
        failure {
            echo '✖ Build failed. Please check the logs for details.'
        }
    }
}