#!/bin/bash

echo "PREPARING CLEAN REPRAPONRAILS INSTALL"
read -p "Press [Enter] key to start..."

# install default database config file
echo "setting up database configuration"
mv config/database.yml.default config/database.yml

# install all gems
echo "bundle install"
bundle install

#/public/uploads säubern  
echo "rm -r public/uploads/*"
rm -r public/uploads/*

# Clear all files in tmp/
echo "rake tmp:clear"
rake tmp:clear

# Clear all files and directories in tmp/cache
echo "rake tmp:cache:clear"
rake tmp:cache:clear

# Clear all files in tmp/sessions
echo "rake tmp:sessions:clear"
rake tmp:sessions:clear

# Clear all files in tmp/sockets
echo "tmp:sockets:clear"
rake tmp:sockets:clear

# Clear log files 
echo "rake log:clear"
rake log:clear

# DB erstellen
echo "RAILS_ENV=production rake db:create"
RAILS_ENV=production rake db:create
    
# DB frisch aufsetzen
echo "RAILS_ENV=production rake db:schema:load"
RAILS_ENV=production rake db:schema:load

# DB mit default-values füllen
echo "RAILS_ENV=production rake db:seed"
RAILS_ENV=production rake db:seed

# Assets frisch kompilieren
echo "rm -r public/assets"
rm -r public/assets
echo "rake assets:precompile"
rake assets:precompile

echo "DONE."

exit 0