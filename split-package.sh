echo "We assume you have done:"
echo git clone git@github.com:pear/Validate.git
echo Go hit https://github.com/organizations/pear/repositories/new to make a new repo
git clone git@github.com:pear/Validate_DE.git

cd Validate_DE
git pull git@github.com:pear/Validate.git
git rm -r *

git reset HEAD package_DE.xml
git checkout -- package_DE.xml
git mv package_DE.xml package.xml
git commit -m "Rename package" package.xml
pear list package.xml | grep ".* /" | cut -f 1 -d " " | xargs git reset HEAD
pear list package.xml | grep ".* /" | cut -f 1 -d " " | xargs git checkout --
git commit -m "Splitting off to own package"

cd ..

cd Validate

pear list package_Finance.xml | grep ".* /" | cut -f 1 -d " " | xargs git rm
git rm package_DE.xml
git reset HEAD LICENSE
git checkout -- LICENSE

git commit -m "Splitting off to own package"


