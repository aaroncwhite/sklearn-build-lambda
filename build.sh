#!/bin/bash
set -ex

export INSTALL_DIR=lib_pack

init () {
    if [ -d "$INSTALL_DIR" ]
    then
         echo Removing old temp dir
         rm -fr $INSTALL_DIR
    fi
    if [ -d build_dir ]
    then
        echo Removing old venv
        rm -fr build_dir
    fi
}

clean_up () {
    echo Cleaning up...
    # rm -fr $INSTALL_DIR
    deactivate
    rm -fr build_dir
}


do_pip () {
    # using pip -t to install directly to our temp dir
    # saves time when looking for the right packages later
    mkdir $INSTALL_DIR
    pip install --upgrade pip wheel
    pip install --use-wheel -r requirements.txt -t $INSTALL_DIR
}

strip_virtualenv () {
    echo "venv original size $(du -sh $INSTALL_DIR | cut -f1)"
    junk=(tests pip wheel easy_install *.pyc)
    for value in "${junk[@]}"
    do
       echo $value
       find $INSTALL_DIR -name $value -exec rm -rf {} +
    done

    find $INSTALL_DIR -name "*.so*" | xargs strip

    echo "venv stripped size $(du -sh $INSTALL_DIR | cut -f1)"

    echo "site-packages size $(du -sh $INSTALL_DIR | cut -f1)"

    pushd $INSTALL_DIR; zip -r -9 -q venv.zip *; popd
    mv $INSTALL_DIR/venv.zip ./
    echo "venv compressed size $(du -sh venv.zip | cut -f1)"
}



main () {
   init

   /usr/bin/virtualenv \
        --python /usr/bin/python build_dev \
        --always-copy \
        --no-site-packages
    source build_dev/bin/activate

    do_pip

    strip_virtualenv

    clean_up
}
main
