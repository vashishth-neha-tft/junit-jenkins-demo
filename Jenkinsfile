pipeline {
    agent any

    parameters {
        string(
            name: 'TOOLS_TO_RUN',
            defaultValue: 'junit,sonarqube,keploy,snyk',
            description: 'Comma-separated list of tools to run (e.g., junit,sonarqube,keploy,snyk)'
        )
    }

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
        TOOLS = "${params.TOOLS_TO_RUN}"
    }

    stages {

        stage('Build & Unit Test') {
            when {
                expression { return TOOLS.contains('junit') }
            }
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            when {
                expression { return TOOLS.contains('sonarqube') || TOOLS.contains('keploy') }
            }
            steps {
                echo 'Checking compiled classes...'
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('SonarQube Scan') {
            when {
                expression { return TOOLS.contains('sonarqube') }
            }
            steps {
                echo 'Running SonarQube scan...'
                withSonarQubeEnv(SONAR_SERVER) {
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

        stage('Install Keploy') {
            when {
                expression { return TOOLS.contains('keploy') }
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
                expression { return TOOLS.contains('keploy') }
            }
            steps {
                echo 'Running Keploy to generate tests...'
                sh '''
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI
                '''
            }
        }

        stage('Install & Run Snyk') {
            when {
                expression { return TOOLS.contains('snyk') }
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
            echo 'Selected tools completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
