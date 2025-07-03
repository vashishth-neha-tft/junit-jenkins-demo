pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {

        stage('Select Test Tools') {
            steps {
                script {
                    def testChoice = input(
                        id: 'testChoice',
                        message: 'Select testing tools to run',
                        parameters: [
                            choice(name: 'TestTools', choices: ['none', 'junit', 'keploy', 'both'], description: 'Choose test tools')
                        ]
                    )
                    env.TEST_TOOLS = testChoice
                }
            }
        }

        stage('Select Analysis Tools') {
            steps {
                script {
                    def analysisChoice = input(
                        id: 'analysisChoice',
                        message: 'Select analysis tools to run',
                        parameters: [
                            choice(name: 'AnalysisTools', choices: ['none', 'sonarqube', 'snyk', 'both'], description: 'Choose analysis tools')
                        ]
                    )
                    env.ANALYSIS_TOOLS = analysisChoice
                }
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

        stage('Install & Run Snyk') {
            when {
                expression { env.ANALYSIS_TOOLS == 'snyk' || env.ANALYSIS_TOOLS == 'both' }
            }
            environment {
                SNYK_TOKEN = credentials('SNYK_TOKEN')
            }
            steps {
                echo 'Installing and running Snyk for vulnerability scanning...'
                sh '''
                    curl -Lo snyk https://static.snyk.io/cli/latest/snyk-linux
                    chmod +x snyk
                    sudo mv snyk /usr/local/bin/snyk || true
                    snyk auth ${SNYK_TOKEN}
                    snyk test || echo "Snyk found vulnerabilities"
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo "Build completed with selected test tools: ${env.TEST_TOOLS}, analysis tools: ${env.ANALYSIS_TOOLS}"
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
