rm -f .bash_history
git rm --cached .bash_history
git reset --soft HEAD~1
git add .
git commit -m "Fix Trade Win Loss Admin Control without secrets"
git push -f origin main
git add . && git commit -m "Update profit rates to 15%-30% for quick trade" && git push
