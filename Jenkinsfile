pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {
        stage('Build & Unit Test') {
            steps {
                echo 'Running Maven build and unit tests...'
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            steps {
                echo 'Checking compiled classes...'
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('SonarQube Scan') {
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
            steps {
                echo 'Running Keploy to generate tests...'
                sh '''
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'Build, Test, Sonar Scan & Keploy Test Generation successful.'
        }
        failure {
            echo 'Pipeline failed. Check logs for errors.'
        }
    }
}
