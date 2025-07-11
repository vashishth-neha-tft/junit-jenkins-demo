pipeline {
    agent any

    environment {
        SONAR_SERVER = "MySonarQube"
        PATH = "${env.WORKSPACE}/.npm-global/bin:/usr/local/bin:$PATH"
        NPM_CONFIG_PREFIX = "${env.WORKSPACE}/.npm-global"
        LOG_DIR = "${env.WORKSPACE}/logs"
    }

    stages {
        stage('Setup Logging') {
            steps {
                sh 'mkdir -p ${LOG_DIR}'
                sh 'rm -f ${LOG_DIR}/*.log || true'
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
                sh 'mvn clean verify -DskipTests=false 2>&1 | tee ${LOG_DIR}/maven_build.log'
                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Verify Compiled Classes') {
            when {
                expression { env.TEST_TOOLS == 'junit' || env.TEST_TOOLS == 'both' }
            }
            steps {
                echo 'Verifying compiled class files...'
                sh 'ls -la target 2>&1 | tee -a ${LOG_DIR}/class_verification.log'
                sh 'ls -la target/classes 2>&1 | tee -a ${LOG_DIR}/class_verification.log || echo "target/classes not found"'
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
                    curl --silent -O -L https://keploy.io/install.sh 2>&1 | tee ${LOG_DIR}/keploy_install.log
                    chmod +x install.sh
                    sudo bash install.sh 2>&1 | tee -a ${LOG_DIR}/keploy_install.log
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
                sh 'sudo -E keploy test -c "mvn spring-boot:run" --delay 5 --disableANSI 2>&1 | tee ${LOG_DIR}/keploy_tests.log'
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
                        --report-path=/path/gitleaks-report.json 2>&1 | tee ${LOG_DIR}/gitleaks_scan.log || echo "Gitleaks completed with findings"
                '''
            }
        }

        stage('Snyk Analysis') {
            when {
                expression { env.SECURITY_TOOLS == 'snyk' || env.SECURITY_TOOLS == 'both' }
            }
            steps {
                echo 'Running Snyk analysis...'
                withCredentials([string(credentialsId: 'snyk-api-token', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        # Set up npm global directory in workspace
                        mkdir -p ${WORKSPACE}/.npm-global
                        npm config set prefix '${WORKSPACE}/.npm-global'
                        
                        # Install Snyk if not present
                        if ! command -v snyk &> /dev/null; then
                            npm install -g snyk 2>&1 | tee ${LOG_DIR}/snyk_install.log
                        fi
                        
                        # Authenticate and run scan
                        snyk auth $SNYK_TOKEN 2>&1 | tee ${LOG_DIR}/snyk_auth.log
                        snyk test --all-projects 2>&1 | tee ${LOG_DIR}/snyk_scan.log
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
                        -Dsonar.surefire.reportsPath=target/surefire-reports 2>&1 | tee ${LOG_DIR}/sonarqube_scan.log
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
                    
                    // Log the upload details
                    writeFile file: "${LOG_DIR}/jfrog_upload.log", text: "Uploaded files matching pattern: target/*.jar"
                }
            }
        }

        // === Step 9: Docker Compliance Check ===
        stage('Docker Snyk Compliance Check') {
            steps {
                script {
                    // Check if Dockerfile exists before proceeding
                    if (fileExists('Dockerfile')) {
                        echo 'Running Snyk Docker compliance check...'
                        withCredentials([string(credentialsId: 'snyk-api-token', variable: 'SNYK_TOKEN')]) {
                            sh '''
                                # Set up npm global directory in workspace
                                mkdir -p ${WORKSPACE}/.npm-global
                                npm config set prefix '${WORKSPACE}/.npm-global'
                                
                                # Install Snyk if not present
                                if ! command -v snyk &> /dev/null; then
                                    npm install -g snyk 2>&1 | tee ${LOG_DIR}/docker_snyk_install.log
                                fi
                                
                                # Build and scan Docker image
                                snyk auth $SNYK_TOKEN 2>&1 | tee ${LOG_DIR}/docker_snyk_auth.log
                                docker build -t myapp:latest . 2>&1 | tee ${LOG_DIR}/docker_build.log
                                snyk container test myapp:latest --file=Dockerfile 2>&1 | tee ${LOG_DIR}/docker_scan.log
                            '''
                        }
                    } else {
                        echo 'Skipping Docker scan: No Dockerfile found in project root'
                        writeFile file: "${LOG_DIR}/docker_scan.log", text: "No Dockerfile found - scan skipped"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
            script {
                // Generate consolidated log
                sh '''
                    echo "===== CONSOLIDATED PIPELINE LOG =====" > ${LOG_DIR}/consolidated_pipeline.log
                    echo "Pipeline execution completed at: $(date)" >> ${LOG_DIR}/consolidated_pipeline.log
                    echo "Test Tools: ${TEST_TOOLS}" >> ${LOG_DIR}/consolidated_pipeline.log
                    echo "Security Tools: ${SECURITY_TOOLS}" >> ${LOG_DIR}/consolidated_pipeline.log
                    echo "QA Tools: ${QA_TOOLS}" >> ${LOG_DIR}/consolidated_pipeline.log
                    echo "" >> ${LOG_DIR}/consolidated_pipeline.log
                    
                    # Append all individual logs
                    for log in ${LOG_DIR}/*.log; do
                        if [ "$(basename $log)" != "consolidated_pipeline.log" ]; then
                            echo "===== $(basename $log) =====" >> ${LOG_DIR}/consolidated_pipeline.log
                            cat $log >> ${LOG_DIR}/consolidated_pipeline.log
                            echo "" >> ${LOG_DIR}/consolidated_pipeline.log
                        fi
                    done
                '''
                
                // Archive all logs
                archiveArtifacts artifacts: 'logs/**/*.log', allowEmptyArchive: true
                
                // Clean up
                sh 'rm -rf ${WORKSPACE}/.npm-global || true'
            }
        }
        success {
            echo "✔ Build succeeded using: Test Tools=${env.TEST_TOOLS}, Security Tools=${env.SECURITY_TOOLS}, QA Tools=${env.QA_TOOLS}"
        }
        failure {
            echo '✖ Build failed. Please check the logs for details.'
            script {
                // Include failure details in logs
                writeFile file: "${LOG_DIR}/pipeline_failure.log", text: "Pipeline failed at stage: ${currentBuild.result}"
            }
        }
        unstable {
            echo 'Build unstable! Tests failed but pipeline continued.'
        }
    }
}