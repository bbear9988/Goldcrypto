rm -f .bash_history
git rm --cached .bash_history
git reset --soft HEAD~1
git add .
git commit -m "Fix Trade Win Loss Admin Control without secrets"
git push -f origin main
git add . && git commit -m "Update profit rates to 15%-30% for quick trade" && git push
git add . && git commit -m "Add Admin control for win loss trading" && git push
git add . && git commit -m "Update full 30 tokens, deposit methods and quick trade panel" && git push
{   "name": "goldcrypto-trading",;   "version": "1.0.0",;   "main": "server.js",;   "scripts": {;     "start": "node server.js";   },;   "dependencies": {;     "express": "^4.18.2";   }
}
git add .
git commit -m "Dua ung dung len web"
git push origin main
git add .
git commit -m "Update new giao dien GoldCrypto"
git push -u origin main --force
git add .
git commit -m "Fix router server.js point to GoldCrypto HTML"
git push origin main
git status
cd <goldcrypto>
ls
