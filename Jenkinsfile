pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        // Add Keploy binary directory to PATH if needed
        PATH = "/usr/local/bin:$PATH"
    }

    stages {
        // Your existing Build & Test, SonarQube, etc.

        stage('Credentials Scanning') {
            steps {
                withSonarQubeEnv(SONAR_SERVER) {
                    sh 'mvn sonar:sonar -Dsonar.security.scan=true'
                }
            }
        }

        stage('SonarQube Artifact Scan') {
            steps {
                withSonarQubeEnv(SONAR_SERVER) {
                    sh 'mvn sonar:sonar -Dsonar.java.binaries=target/classes'
                }
            }
        }

        stage('Install Keploy') {
            steps {
                sh '''
                    curl --silent -O -L https://keploy.io/install.sh
                    chmod +x install.sh
                    bash install.sh

                    # Move to PATH if not automatically done
                    sudo mv keploy /usr/local/bin/keploy || true
                    sudo chmod +x /usr/local/bin/keploy
                '''
            }
        }

        stage('Run Keploy Tests') {
            steps {
                sh '''
                    # Assuming your app can be run like this
                    # Modify the command according to your app entry point
                    sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI
                '''
            }
        }
    }
}
