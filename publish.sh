#!/bin/bash

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

echo "Delete old publication..."
rm -rf public
git worktree prune

echo "Checkout master branch into public..."
git worktree add -B master public origin/master

echo "Clean up public directory..."
rm -rf public/*

echo "Generating site..."
hugo

echo "Updating master branch..."
cd public && git add --all && git commit -m "Publishing post"

echo "Push to origin"
git push origin master
