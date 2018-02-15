#!/bin/bash
set -ex


do_pip () {
    pip install --upgrade pip wheel
    test -f requirements.txt && pip install --use-wheel -r requirements.txt
    pip install --use-wheel --no-binary numpy numpy
    pip install --use-wheel --no-binary scipy scipy
    pip install --use-wheel sklearn
}

strip_virtualenv () {
    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
    find $VIRTUAL_ENV/lib64/python2.7/site-packages/ -name "*.so" | xargs strip
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    pushd $VIRTUAL_ENV/lib/python2.7/site-packages/ && zip -r -9 -q ~/partial-venv.zip * ; popd
    pushd $VIRTUAL_ENV/lib64/python2.7/site-packages/ && zip -r -9 --out ~/venv.zip -q ~/partial-venv.zip * ; popd
    echo "site-packages compressed size $(du -sh ~/venv.zip | cut -f1)"

    pushd $VIRTUAL_ENV && zip -r -q ~/full-venv.zip * ; popd
    echo "venv compressed size $(du -sh ~/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python2.7/site-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python2.7/site-packages/lib || true
    cp /usr/lib64/atlas/* $libdir
    cp /usr/lib64/libquadmath.so.0 $libdir
    cp /usr/lib64/libgfortran.so.3 $libdir
}

main () {
    /usr/bin/virtualenv \
        --python /usr/bin/python sklearn_build_dev \
        --always-copy \
        --no-site-packages
    source sklearn_build_dev/bin/activate

    do_pip

    shared_libs

    strip_virtualenv
}
main
