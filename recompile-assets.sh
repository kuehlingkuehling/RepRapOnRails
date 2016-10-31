#!/bin/bash

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

# Assets frisch kompilieren
echo "rm -r public/assets"
rm -r public/assets
echo "RAILS_ENV=production rake assets:precompile"
RAILS_ENV=production rake assets:precompile

echo "DONE."

exit 0

