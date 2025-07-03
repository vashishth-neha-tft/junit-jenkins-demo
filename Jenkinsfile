pipeline {
    agent any

    parameters {
        choice(
            name: 'TEST_TOOLS',
            choices: ['none', 'junit', 'keploy', 'junit,keploy'],
            description: 'Select test tools to run (choose junit, keploy, or both)'
        )

        choice(
            name: 'ANALYSIS_TOOLS',
            choices: ['none', 'sonarqube', 'snyk', 'sonarqube,snyk'],
            description: 'Select analysis tools to run (choose sonarqube, snyk, or both)'
        )
    }

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {

        stage('Build & Unit Test') {
            when {
                expression { params.TEST_TOOLS.toLowerCase().contains('junit') }
            }
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            when {
                expression { params.TEST_TOOLS.toLowerCase().contains('junit') }
            }
            steps {
                echo 'Checking compiled classes...'
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('Install Keploy') {
            when {
                expression { params.TEST_TOOLS.toLowerCase().contains('keploy') }
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
                expression { params.TEST_TOOLS.toLowerCase().contains('keploy') }
            }
            steps {
                echo 'Running Keploy to generate tests...'
                sh '''
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI
                '''
            }
        }

        stage('SonarQube Scan') {
            when {
                expression { params.ANALYSIS_TOOLS.toLowerCase().contains('sonarqube') }
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
                expression { params.ANALYSIS_TOOLS.toLowerCase().contains('snyk') }
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
            echo "Build completed with selected test tools: ${params.TEST_TOOLS}, analysis tools: ${params.ANALYSIS_TOOLS}"
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
