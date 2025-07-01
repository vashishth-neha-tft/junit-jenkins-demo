pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "/usr/local/bin:$PATH"
    }

    stages {

        stage('Build & Unit Test') {
            steps {
                sh 'mvn clean verify -DskipTests=false'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify target/classes') {
            steps {
                sh 'ls -la target'
                sh 'ls -la target/classes || echo "target/classes not found"'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv(SONAR_SERVER) {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=junit-jenkins-demo \
                        -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }

        stage('Install Keploy') {
            steps {
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
                sh '''
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI
                '''
            }
        }
    }
}
