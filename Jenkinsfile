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
            parallel {
                stage('SonarQube Creds Scan') {
                    steps {
                        withSonarQubeEnv(SONAR_SERVER) {
                            sh 'mvn sonar:sonar -Dsonar.security.scan=true'
                        }
                    }
                }
                stage('Gitleaks Scan') {
                    steps {
                        sh '''
                            curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.0.0/gitleaks_8.0.0_linux_x64.tar.gz | tar xz
                            ./gitleaks detect --source=. --report-format=json --report-path=gitleaks-report.json

                            if [ -s gitleaks-report.json ]; then
                                echo "Credentials leaks detected!"
                                cat gitleaks-report.json
                                exit 1
                            fi
                        '''
                    }
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
