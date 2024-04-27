#!/bin/bash

echo -e "\033[32m [Switch to source branch and update repo...] \033[0m"
git checkout source
git pull origin source
if [[ $? -ne 0 ]]
then
    echo -e "\033[31m The working directory is dirty...] \033[0m"
    exit 1
fi

if [[ $(git status -s) ]]
then
    echo -e "\033[32m [Commit new posts first...] \033[0m"
    rm content/blog/*~
    git add --all && git commit -m "commit post"
    git push origin source
fi

echo -e "\033[32m [Delete old publication...] \033[0m"
rm -rf public
git worktree prune

echo -e "\033[32m [Checkout master branch into public...] \033[0m"
git worktree add -B master public origin/master

echo -e "\033[32m [Clean up public directory...] \033[0m"
rm -rf public/*

echo -e "\033[32m [Add Readme file...] \033[0m"
echo "Welcome to my [BLOG](https://yunyanan.github.io/). This branch is used to store
publish files of blog." > public/Readme.md

echo -e "\033[32m [Generating site...] \033[0m"
hugo

echo -e "\033[32m [Copy Google search verify file...] \033[0m"
cp google43ebdfe4fa803825.html public/

echo -e "\033[32m [Copy Sitemap file...] \033[0m"
cp sitemap.xml public/

echo -e "\033[32m [Updating master branch...] \033[0m"
cd public && git add --all && git commit -m "Publishing post"

echo -e "\033[32m [Push to origin master...] \033[0m"
git push origin master
cd -

echo -e "\033[32m [Publish finished] \033[0m"
