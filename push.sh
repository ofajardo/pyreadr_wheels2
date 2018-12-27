setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_website_files() {
  #git checkout -b gh-pages
  git checkout master
  git pull
  git add wheels
  git commit -m "Travis build: $TRAVIS_BUILD_NUMBER" -m "[skip ci]"
}

upload_files() {
# Remove existing "origin"
  git remote rm origin
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://ofajardo:${GH_TOKEN}@github.com/ofajardo/pyreadr_wheels.git > /dev/null 2>&1
  git push origin master --quiet
  
}

echo "Travis JOb: $TRAVIS_JOB_NUMBER"
numjob=$(echo $TRAVIS_JOB_NUMBER | cut -d'.' -f2)
echo "sleeping $((($numjob-1)*60))"
sleep $((($numjob-1)*10))
  setup_git
  commit_website_files
  upload_files
#else
#  echo "Wheels not ready yet"
#fi


