#!/bin/bash

echo "Switch to source branch and update repo..."
git checkout source
git pull origin source
if [[ $? -ne 0 ]]
then
    echo "The working directory is dirty."
    exit 1
fi

if [[ $(git status -s) ]]
then
    echo "Commit new posts first."
    git add --all && git commit -m "commit post"
    git push origin source
fi

echo "Delete old publication..."
rm -rf public
git worktree prune

echo "Checkout master branch into public..."
git worktree add -B master public origin/master

echo "Clean up public directory..."
rm -rf public/*

echo "Add Readme file..."
touch public/Readme.md
echo "This is my blog repo, Welcome to my [blog](https://yunyanan.github.io/)." > public/Readme.md

echo "Generating site..."
hugo

echo "Updating master branch..."
cd public && git add --all && git commit -m "Publishing post"

echo "Push to origin"
git push origin master
cd -
