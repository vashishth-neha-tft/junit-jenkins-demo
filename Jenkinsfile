pipeline {
    agent any

    environment {
        RUN_JUNIT = 'false'
        RUN_KEPLOY = 'false'
    }

    stages {
        stage('Select Test Type') {
            steps {
                script {
                    def choice = input message: 'Which tests would you like to run?', parameters: [
                        choice(name: 'TEST_TYPE', choices: ['junit', 'keploy', 'both'], description: 'Select test type')
                    ]

                    if (choice == 'junit') {
                        RUN_JUNIT = 'true'
                    } else if (choice == 'keploy') {
                        RUN_KEPLOY = 'true'
                    } else if (choice == 'both') {
                        RUN_JUNIT = 'true'
                        RUN_KEPLOY = 'true'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('JUnit Test') {
            steps {
                script {
                    if (RUN_JUNIT == 'true') {
                        echo "Running JUnit tests..."
                        sh 'mvn test'
                    } else {
                        echo "Skipping JUnit tests."
                    }
                }
            }
        }

        stage('Keploy Test') {
            steps {
                script {
                    if (RUN_KEPLOY == 'true') {
                        echo "Running Keploy tests..."
                        sh '''
                        # Download Keploy CLI (if not already installed)
                        if ! command -v keploy &> /dev/null; then
                          curl -s https://raw.githubusercontent.com/keploy/keploy/main/install.sh | bash
                        fi

                        # Run keploy test
                        keploy test -c "java -cp target/classes com.example.StringUtils"
                        '''
                    } else {
                        echo "Skipping Keploy tests."
                    }
                }
            }
        }

        stage('Archive JUnit Results') {
            steps {
                script {
                    if (RUN_JUNIT == 'true') {
                        echo "Archiving JUnit results..."
                        junit 'target/surefire-reports/*.xml'
                    } else {
                        echo "Skipping JUnit results archiving."
                    }
                }
            }
        }

        stage('Archive Keploy Results') {
            steps {
                script {
                    if (RUN_KEPLOY == 'true') {
                        echo "Archiving Keploy results..."
                        archiveArtifacts artifacts: 'keploy/reports/**', allowEmptyArchive: true
                    } else {
                        echo "Skipping Keploy results archiving."
                    }
                }
            }
        }
    }
}
