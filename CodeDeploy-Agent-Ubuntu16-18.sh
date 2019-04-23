#!/bin/bash
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

\curl -sSL https://get.rvm.io | bash -s stable --ruby=2.3.0

echo 'source /usr/local/rvm/scripts/rvm' >> /etc/profile
echo 'source /usr/local/rvm/scripts/rvm' >> ~/.bashrc
source /usr/local/rvm/scripts/rvm
source ~/.bashrc

ruby -v

gem install bundler

cd /opt
git clone https://github.com/aws/aws-codedeploy-agent.git codedeploy-agent
cd codedeploy-agent
bundle install
rake clean && rake

cp /opt/codedeploy-agent/init.d/codedeploy-agent /etc/init.d/
systemctl daemon-reload
systemctl start codedeploy-agent
systemctl enable codedeploy-agent