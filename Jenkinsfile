pipeline {
    agent {
        label "backagent"
    }
    environment {
        DOCKER_REG = credentials('DOCKER_REG')
        CORE_API_TOKEN = credentials('CORE_API_TOKEN')
        COMMON_PROTO_TOKEN = credentials('COMMON_PROTO_TOKEN')
        ARTIFACTORY_USER = credentials('ARTIFACTORY_USER')
        ARTIFACTORY_PASS = credentials('ARTIFACTORY_PASS')
        VAULT_PASS = credentials('VAULT_PASS')
        MS_HOME_DIR = "${env.WORKSPACE}"
        MS_NAME = 'ms-config-constructor'
        NAMESPACE = 'test'
        GITLAB_CI = "true"
    }
    stages {
        stage('Check ver') {
            steps {
                script {
                    def lastCommitMessage = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                    if (lastCommitMessage =~ /Update version to [0-9a-zA-Z\.]+/) {
                        echo "Nikuda ne edem, stope."
                        //time to fix
                        System.exit(0)
                    }
                    echo "Last commit message does not version update. Zavodim traktor."
                        }
                   }
            }

        stage('Checkout branch') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-logopass', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    git branch: env.BRANCH_NAME, url: 'http://' + env.USERNAME + ':' + env.PASSWORD + '@youdomain.com/campaign-new-arch/ms-config-constructor.git'
                    sh """
                        git clean -n -f -d
                        git pull .
                        echo ${MS_NAME}
                        """
                    }
                }
            }


        stage('Up Version MS') {
            steps {
                script {
                    def version = readFile('version.txt').trim()
                    env.MS_VERSION = version
                    def versionParts = version.split("\\.")
                    versionParts[-1] = (versionParts[-1].toInteger() + 1).toString()
                    env.CURRENT_VERSION = versionParts.join('.')
                    writeFile file: 'version.txt', text: "${env.CURRENT_VERSION}"
                }
            }
        }

        stage ('Clone ms-core-root/common-proto') {
            steps {
                sh """
                    rm -rf ms-core-root
                    rm -rf common-proto
                    git clone http://gitlab+deploy-token-1:$CORE_API_TOKEN@youdomain.com/campaign-new-arch/ms-core-root.git --depth 1 ms-core-root
                    git clone http://gitlab+deploy-token-1:$COMMON_PROTO_TOKEN@youdomain.com/campaign-new-arch/common-proto.git --depth 1 common-proto
                """
            }
        }
        stage ('Move CI project') {
            steps {
                sh 'rsync -a \${MS_HOME_DIR}/ ms-core-root/\${MS_NAME} --exclude=\'ms-core-root\''
            }
        }
        stage ('Build project') {
            steps {
                sh """
                    gradle -v
                    cd ${MS_HOME_DIR}/ms-core-root/${MS_NAME}
                    gradle assemble -P gradle.properties -PARTIFACTORY_USER=$ARTIFACTORY_USER -PARTIFACTORY_PASS=$ARTIFACTORY_PASS --build-cache --gradle-user-home cache/ 
                """
            }
        }

        stage('Docker build/tag/push') {
            steps {
                sh """
                    rm ${MS_HOME_DIR}/*.jar || true
                    cp ${MS_HOME_DIR}/ms-core-root/${MS_NAME}/build/libs/* ${MS_HOME_DIR}/
                    docker build -t ${MS_NAME}:${env.MS_VERSION} ${MS_HOME_DIR}/.
                    docker tag ${MS_NAME}:${env.MS_VERSION} ${DOCKER_REG}/${MS_NAME}:${env.MS_VERSION}
                    docker push ${DOCKER_REG}/${MS_NAME}:${env.MS_VERSION}
                """
            }
        }

        // stage('Test') {
        //     steps {
        //         echo 'Testing..'
        //     }
        // }

        stage('Pull Helm') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-logopass', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                dir("helm") {
                    git branch: 'test-contour', url: 'http://' + env.USERNAME + ':' + env.PASSWORD + '@youdomain.com/campaign-new-arch/infra.git'
                    }
                }
            }
        }

        stage('Set Helm release ver') {
            steps {
                sh """
                    chmod +x ./ver.sh
                    ./ver.sh
                """
                }
            }

        stage("Write vault password to file") {
            steps {
                withCredentials([string(credentialsId: 'VAULT_PASS', variable: 'VAULT_PASS')]) {
                    sh "echo $VAULT_PASS > ./helm/pass.txt"
                }
            }
        }


        stage("Decrypt secrets") {
            steps {
                withCredentials([string(credentialsId: 'VAULT_PASS', variable: 'VAULT_PASS')]) {
                    script {
                        sh "find ./helm/charts/work/ -name secrets.yaml | xargs -I {} ansible-vault decrypt {} --vault-password-file ./helm/pass.txt"
                    }
                }
            }
        }


        stage('Deploy') {
            steps {
                sh """
                    helm upgrade --install ${MS_NAME} -n ${NAMESPACE} helm/charts/work/charts/${MS_NAME} --values helm/charts/work/values.yaml --values helm/charts/work/charts/${MS_NAME}/values.yaml
                    rm -rf helm
                """
                }
            }

        stage('Push new VER of MS') {
            steps {
                sh """
                    git add version.txt
                    git commit -m 'Update version to ${env.CURRENT_VERSION}'
                    git push origin $BRANCH_NAME
                """
                }
            }


        stage('Clean Workspace') {
            steps {
                cleanWs()
                }
                    post {
                        success {
                        cleanWs()
                    }
                }
            }

        }
    }
