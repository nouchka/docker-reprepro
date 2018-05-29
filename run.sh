#!/bin/bash

set -m
export GNUPGHOME="/data/.gnupg"
echo "REPREPRO_BASE_DIR=$REPREPRO_BASE_DIR" > /etc/environment

if [ -f "/config/secring.gpg" ]
then
    perms=$(stat -c %a /config/secring.gpg)
    if [ "${perms: -1}" != "0" ]
    then
        echo "/config/secring.gpg gnupg private key should not be readable by others..."
        echo "=> Aborting!"
        exit 1
    fi
fi
if [ -d "${GNUPGHOME}" ]
then
    echo "=> /data/.gnupg directory already exists:"
    echo "   So gnupg seems to be already configured, nothing to do..."
else
    echo "=> /data/.gnupg directory does not exist:"
    echo "   Configuring gnupg for reprepro user..."
    gpg --import /config/pubring.gpg
    if [ $? -ne 0 ]; then
        echo "=> Failed to import gnupg public key for reprepro..."
        echo "=> Aborting!"
        exit 1
    fi
    gpg --allow-secret-key-import --import /config/secring.gpg
    if [ $? -ne 0 ]; then
        echo "=> Failed to import gnupg private key for reprepro..."
        echo "=> Aborting!"
        exit 1
    fi
    chown -R reprepro:reprepro ${GNUPGHOME}
fi

if [ -d "$REPREPRO_BASE_DIR" ]
then
    echo "=> $REPREPRO_BASE_DIR directory already exists:"
    echo "   So reprepro seems to be already configured, nothing to do..."
else
    echo "=> $REPREPRO_BASE_DIR directory does not exist:"
    echo "   Configuring a default debian repository with reprepro..."

    keyid=$(gpg --list-secret-keys --keyid-format SHORT | grep "^sec " | sed "s/.*\/\([^ ]*\).*/\1/")
    if [ -z "$keyid" ]
    then
        echo "=> Please provide /config/pubring.gpg file to guess the key id to use for reprepro to sign pakages..."
        echo "=> Aborting!"
        exit 1
    fi

    mkdir -p $REPREPRO_BASE_DIR/{tmp,incoming,conf}

    cat << EOF > $REPREPRO_BASE_DIR/conf/options
verbose
basedir $REPREPRO_BASE_DIR
gnupghome ${GNUPGHOME}
ask-passphrase
EOF

    for dist in $(echo ${RPP_DISTRIBUTIONS} | tr ";" "\n"); do
        dcodename_var="RPP_CODENAME_${dist}"
        darchs_var="RPP_ARCHITECTURES_${dist}"
        dcomps_var="RPP_COMPONENTS_${dist}"
        dcodename="${!dcodename_var}"
        if [ -z "${dcodename}" ]; then
            echo "=> No codename supplied for distribution ${dist}: falling back to ${dist} codename"
            dcodename=${dist}
        fi
        cat << EOF >> $REPREPRO_BASE_DIR/conf/distributions
Origin: ${REPREPRO_DEFAULT_NAME}
Label: ${REPREPRO_DEFAULT_NAME}
Codename: ${dcodename}
Architectures: ${!darchs_var:-"i386 amd64 armhf source"}
Components: ${!dcomps_var:-"main"}
Description: ${REPREPRO_DEFAULT_NAME} debian repository
DebOverride: override.${dist}
DscOverride: override.${dist}
SignWith: ${keyid}

EOF
        touch $REPREPRO_BASE_DIR/conf/override.${dist}
    done

    for incoming in $(echo ${RPP_INCOMINGS} | tr ";" "\n"); do
        iallow_var="RPP_ALLOW_${incoming}"
        mkdir -p $REPREPRO_BASE_DIR/incoming/${incoming} $REPREPRO_BASE_DIR/tmp/${incoming}
        cat << EOF >> $REPREPRO_BASE_DIR/conf/incoming
Name: ${incoming}
IncomingDir: $REPREPRO_BASE_DIR/incoming/${incoming}
TempDir: $REPREPRO_INCOMING_DIR/${incoming}
Allow: ${!iallow_var}
Cleanup: on_deny on_error

EOF
    done
    chown -R reprepro:reprepro $REPREPRO_BASE_DIR
fi

##Auto import
for incoming in $(echo ${RPP_INCOMINGS} | tr ";" "\n"); do
	iallow_var="RPP_ALLOW_${incoming}"
	dist=$(echo ${!iallow_var}|awk -F '>' '{print $2}')
	[ -d "$REPREPRO_INCOMING_DIR/$dist" ] || continue
	find $REPREPRO_INCOMING_DIR/$dist -type f -name "*.deb"| while read i
	do
		reprepro --basedir=$REPREPRO_BASE_DIR includedeb $dist $i
	done
done

## allow clean exit to build
[ ! "$1" ] || exit 0

##clean check
cd $REPREPRO_BASE_DIR
reprepro check
reprepro clearvanished

[ -f "/var/www/html/repo" ] || ln -s $REPREPRO_BASE_DIR /var/www/html/repo
gpg --export > /var/www/html/repository.key

echo "=> Starting lighttpd server..."
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf

