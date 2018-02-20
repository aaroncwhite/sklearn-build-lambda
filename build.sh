#!/bin/bash
set -ex

export INSTALL_DIR=lib_pack

if [ -z "$VIRTUAL_ENV" ]; then
    VIRTUAL_ENV=./build_dev
fi


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

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python2.7/dist-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python2.7/dist-packages/lib || true
    cp /usr/lib64/atlas/* $libdir
    cp /usr/lib64/libquadmath.so.0 $libdir
    cp /usr/lib64/libgfortran.so.3 $libdir

    lib32=$VIRTUAL_ENV/lib/python2.7/dist-packages
    if [ -d $lib32 ]; then
        cp -r $lib32/* $INSTALL_DIR
    fi

    lib64=$VIRTUAL_ENV/lib64/python2.7/dist-packages
    if [ -d $lib64 ]; then
        cp -r $lib64/* $INSTALL_DIR
    fi

}

do_pip () {
    # using pip -t to install directly to our temp dir
    # saves time when looking for the right packages later
    mkdir $INSTALL_DIR
    pip install --upgrade pip wheel
    pip install --use-wheel -r requirements.txt
}

strip_virtualenv () {
    echo "venv original size $(du -sh $INSTALL_DIR | cut -f1)"
    junk=(tests pip wheel easy_install *.pyc *.zip)
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



complete () {
   init

   /usr/bin/virtualenv \
        --python /usr/bin/python build_dev \
        --always-copy \
        --no-site-packages
    source build_dev/bin/activate

    do_pip
    shared_libs

    strip_virtualenv

    clean_up
}

build_only () {
    init

   /usr/bin/virtualenv \
        --python /usr/bin/python build_dev \
        --always-copy \
        --no-site-packages
    source build_dev/bin/activate

    do_pip
    shared_libs
}

post_s3 () {
   aws s3 cp venv.zips3://$2/$3.zip
}

case "$1" in
    (build_only)
      build_only
      exit 1
      ;;
    (complete)
      complete
      exit 1
      ;;
    (strip_zip)
      shared_libs
      strip_virtualenv
      exit 1
      ;;
    (post_s3)
      post_s3
      exit 1
      ;;
    (*)
      echo "Usage: $0 {build_only|complete|strip_zip}"
      exit 2
      ;;
esac
