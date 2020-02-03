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
echo "This is my blog repo, Welcome to my [blog](https://yunyanan.github.io/)." > public/Readme.md

echo -e "\033[32m [Generating site...] \033[0m"
hugo

echo -e "\033[32m [Updating master branch...] \033[0m"
cd public && git add --all && git commit -m "Publishing post"

echo -e "\033[32m [Push to origin] \033[0m"
git push origin master
cd -
