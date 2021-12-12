#!/bin/bash

GO_STORE_DIR=$HOME/Libs/sources/go
SYS_ARCH=$(uname -m)
OS=$(uname -s)
GOVERSION=$1

DT=$(date "+%Y%m%d%H%M%S")
OS_TYPE=linux
OS_ARCH=amd64

SHA_CMD=sha256sum

if [[ $OS == "Darwin" ]] ; then
    OS_TYPE=darwin
    SHA_CMD="shasum -a 256"
elif [[ $OS == "Linux" ]] ; then
    OS_TYPE=linux
fi

if [[ $SYS_ARCH == "x86_64" ]]; then
    OS_ARCH=amd64
fi


MAINFILE=go$GOVERSION.$OS_TYPE-$OS_ARCH
DOWNLOAD_URL=https://go.dev/dl/$MAINFILE.tar.gz
SHA_URL=https://mirrors.ustc.edu.cn/golang/$MAINFILE.tar.gz.sha256
EXTRACT_DIR=$GO_STORE_DIR/go$GOVERSION
TARFILE=$MAINFILE-store.tar.gz

GO_TAR_EXIST=0
GO_TAR_SHA_MATCH=0

ENV_GO=$HOME/go

TEMPDIR=/tmp/getgo_tmp/gosrc_$GOVERSION\_$OS_TYPE\_$OS_ARCH\_$DT

check_go_tar_exist() {
    echo "================================"

    echo " ** Checking go tar..."

    echo ""
    if [[ -f $GO_STORE_DIR/$TARFILE ]]; then
            check_go_tar_sha256
            return
    fi

}

check_go_tar_sha256() {

    echo " *** checking go tar"
    file_sha_opt=$($SHA_CMD $GO_STORE_DIR/$TARFILE)
    file_sha=${file_sha_opt:0:64}
    net_sha=$(curl $SHA_URL)
    if [[ $file_sha != $net_sha ]]; then
        echo "SHA not match, please check."
        echo "Local file sha256: $file_sha"
        echo "Net sha256: $net_sha"
        return
    fi

    echo ""
    echo " *** Checksum matches."
    echo ""
    GO_TAR_EXIST=1
}

download_go_tar() {
    echo "================================"

    echo " ** Downloading Go Tar **"
    echo ""
    mkdir -pv $GO_STORE_DIR
    if [[ GO_TAR_EXIST -eq 1 ]]; then
        echo " Go tar exists, skip download"
        return
    fi

    mkdir -pv $GO_STORE_DIR 
    wget $DOWNLOAD_URL -O $GO_STORE_DIR/$TARFILE

    echo ""
    if [[ $? -ne 0 ]]; then
        echo " ** WGET returns non-zero, quitting"
        exit
    fi

    check_go_tar_sha256
    echo ""
}

extract_go_tar() {
    echo "================================"
    echo "** Extract **"

    echo ""

    WRITE_DIR=1

    if [[ -d "$EXTRACT_DIR" ]] ; then
        read -p "Extract directory $EXTRACT_DIR already exists, overwrite? [y/N] " OW_CONFIRM
        if [[ $OW_CONFIRM != "y" ]]; then
            echo "Skip overwrite."
            echo ""
            WRITE_DIR=0
        fi
    fi

    if [ $WRITE_DIR -eq 1 ]
    then
        echo "extracting to dir: $TEMPDIR"
        mkdir -pv $TEMPDIR
        tar -xf $GO_STORE_DIR/$TARFILE -C $TEMPDIR
        mv $TEMPDIR/go $EXTRACT_DIR 
    fi
    echo ""
}

install_go_link() {
    echo "================================"
    echo " ** Install **"

    echo ""
    read -p "Install to $ENV_GO ? [y/N] " INST_CONFIRM

    echo ""
    if [[ $INST_CONFIRM == "y" ]]; then
        echo "Installing"
        rm $HOME/go
        ln -s $EXTRACT_DIR $ENV_GO
    fi
    echo ""
}


cleanup() {
    echo "================================"
    echo " ** Clean up **"

    echo ""
    rm -rf /tmp/getgo_tmp
    # rm -rf $GO_STORE_DIR/$TARFILE
}



echo " ** Summary ** "
echo " OS:         $OS_TYPE"
echo " ARCH:       $OS_ARCH"
echo " VERSION:    $GOVERSION"
echo " FILE:       $MAINFILE"
echo " DOWNLOAD:   $DOWNLOAD_URL"
echo " Tar Stored: $TARFILE"
echo " Extract to: $EXTRACT_DIR"
echo ""
read -p "Please confirm and continue to download [y/n] " CONFIRM

if [[ $CONFIRM != "y" ]]; then
    exit
fi

check_go_tar_exist
download_go_tar
extract_go_tar
install_go_link
cleanup
