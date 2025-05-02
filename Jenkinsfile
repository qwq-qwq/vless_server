pipeline {
    agent any
    
    environment {
        UUID = "${UUID}"
        DOMAIN = "${DOMAIN ?: 'vless-server.perek.rest'}"
        APP_DIR = "/opt/projects/vless-server"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Prepare Configuration') {
            steps {
                // Create required directories
                sh "mkdir -p ${env.APP_DIR}/logs ${env.APP_DIR}/config"
                // Copy configuration files
                sh "cp config/config.json ${env.APP_DIR}/config/config.json || true"
                
                // Generate UUID if not provided
                script {
                    if (!env.UUID) {
                        env.UUID = sh(script: 'uuidgen', returnStdout: true).trim()
                        echo "Generated UUID: ${env.UUID}"
                    }
                }
                
                // Update client UUID in config
                sh "sed -i 's/YOUR_UUID_HERE/${env.UUID}/g' config/config.json"
            }
        }
        
        stage('Deploy') {
            steps {
                // Check if traefik_web-network exists, create if it doesn't
                sh '''
                    if ! docker network ls | grep -q traefik_web-network; then 
                        docker network create traefik_web-network
                    fi
                '''
                
                // Deploy using Docker Compose
                sh 'docker-compose down || true'
                sh 'docker-compose up -d'
            }
        }
        
        stage('Verify') {
            steps {
                // Check if the container is running
                sh 'docker-compose ps'
            }
        }
    }
    
    post {
        success {
            echo "VLESS server successfully deployed!"
            echo "Connection Information:"
            echo "Domain: ${DOMAIN}"
            echo "Port: 443"
            echo "UUID: ${UUID}"
            echo "Protocol: VLESS"
            echo "Network: tcp"
            echo "Using external Traefik for SSL termination"
        }
        
        failure {
            echo "Deployment failed. Check logs for details."
        }
    }
}